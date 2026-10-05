import Foundation
import Accelerate

struct ClassifierData: Codable {
    var weights: [Float]?
    var bias: Float
    var iterations: Int
    /// Running history of all training samples for replay.
    var historyEmbeddings: [[Float]]?
    var historyLabels: [Float]?
}

class AestheticClassifier {
    var weights: [Float]?
    var bias: Float = 0.0
    var iterations: Int = 0

    var batchEmbeddings: [[Float]] = []
    var batchLabels: [Float] = []

    /// Full training history for replaying during training.
    private var historyEmbeddings: [[Float]] = []
    private var historyLabels: [Float] = []

    private let storageURL: URL

    private func getFileURL() -> URL { storageURL }

    init(storageURL: URL? = nil) {
        self.storageURL = storageURL ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("ClassifierData.json")
        let url = getFileURL()
        if let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode(ClassifierData.self, from: data) {
            weights = decoded.weights
            bias = decoded.bias
            iterations = decoded.iterations
            historyEmbeddings = decoded.historyEmbeddings ?? []
            historyLabels = decoded.historyLabels ?? []
        }
    }

    func save() {
        let dataToSave = ClassifierData(
            weights: weights,
            bias: bias,
            iterations: iterations,
            historyEmbeddings: historyEmbeddings,
            historyLabels: historyLabels
        )
        if let encoded = try? JSONEncoder().encode(dataToSave) {
            try? encoded.write(to: getFileURL(), options: .atomic)
        }
    }

    func reset() {
        weights = nil
        bias = 0.0
        iterations = 0
        batchEmbeddings.removeAll()
        batchLabels.removeAll()
        historyEmbeddings.removeAll()
        historyLabels.removeAll()
        try? FileManager.default.removeItem(at: getFileURL())
    }

    func predict(embedding: [Float]) -> Float {
        guard let w = weights, w.count == embedding.count else {
            return 0.5
        }

        // Use Accelerate for fast dot product
        var dotProduct: Float = 0.0
        vDSP_dotpr(w, 1, embedding, 1, &dotProduct, vDSP_Length(w.count))
        dotProduct += bias

        return 1.0 / (1.0 + exp(-dotProduct))
    }

    var isTrained: Bool {
        weights != nil && iterations > 0
    }

    var totalSamples: Int {
        historyEmbeddings.count
    }

    func update(embedding: [Float], label: Float) {
        guard !embedding.isEmpty, embedding.allSatisfy({ $0.isFinite }),
              label == 0 || label == 1,
              weights == nil || weights?.count == embedding.count else { return }
        if weights == nil {
            weights = [Float](repeating: 0.0, count: embedding.count)
        }
        batchEmbeddings.append(embedding)
        batchLabels.append(label)
    }

    func undoLastUpdate() -> Bool {
        if !batchEmbeddings.isEmpty {
            batchEmbeddings.removeLast()
            batchLabels.removeLast()
            return true
        }
        return false
    }

    func flushBatch() {
        guard !batchEmbeddings.isEmpty else { return }

        let dim = batchEmbeddings[0].count
        if weights == nil {
            weights = [Float](repeating: 0.0, count: dim)
        }

        // Add new samples to history
        historyEmbeddings.append(contentsOf: batchEmbeddings)
        historyLabels.append(contentsOf: batchLabels)

        // Cap history at 500 samples (keep most recent)
        if historyEmbeddings.count > 500 {
            let excess = historyEmbeddings.count - 500
            historyEmbeddings.removeFirst(excess)
            historyLabels.removeFirst(excess)
        }

        batchEmbeddings.removeAll()
        batchLabels.removeAll()

        // Retrain from scratch on full history for best results
        trainOnHistory()

        iterations += 1
        save()
    }

    /// Full retrain on all history data with multiple epochs.
    private func trainOnHistory() {
        guard !historyEmbeddings.isEmpty else { return }

        let dim = historyEmbeddings[0].count
        let n = historyEmbeddings.count

        // Reset weights for clean training
        var w = [Float](repeating: 0.0, count: dim)
        var b: Float = 0.0

        // SGD with multiple epochs
        let epochs = min(50, max(20, 200 / n)) // More epochs when few samples
        let lr: Float = 0.1 // Slower learning rate to avoid exploding weights
        let lambda: Float = 0.01 // L2 regularization (weight decay)

        for epoch in 0..<epochs {
            let decayedLR = lr / (1.0 + 0.05 * Float(epoch))

            var gradW = [Float](repeating: 0.0, count: dim)
            var gradB: Float = 0.0

            for i in 0..<n {
                let emb = historyEmbeddings[i]
                let label = historyLabels[i]

                // Forward pass
                var dot: Float = 0.0
                vDSP_dotpr(w, 1, emb, 1, &dot, vDSP_Length(dim))
                dot += b

                // Clamp dot product to prevent exp() overflow/underflow
                dot = max(-20.0, min(20.0, dot))
                let pred = 1.0 / (1.0 + exp(-dot))
                let error = pred - label

                // Accumulate gradients
                gradB += error
                var scaledError = error
                vDSP_vsma(emb, 1, &scaledError, gradW, 1, &gradW, 1, vDSP_Length(dim))
            }

            let batchSize = Float(n)
            let step = -(decayedLR / batchSize)

            // Apply weight decay (L2): w = w * (1 - lr * lambda)
            var decayFactor = 1.0 - decayedLR * lambda
            vDSP_vsmul(w, 1, &decayFactor, &w, 1, vDSP_Length(dim))

            // Apply gradient step: w = w + gradW * step
            var stepVar = step
            vDSP_vsma(gradW, 1, &stepVar, w, 1, &w, 1, vDSP_Length(dim))

            b -= decayedLR * (gradB / batchSize)
        }

        weights = w
        bias = b
    }
}
