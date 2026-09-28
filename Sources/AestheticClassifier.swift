import Foundation

struct ClassifierData: Codable {
    var weights: [Float]?
    var bias: Float
    var iterations: Int
}

class AestheticClassifier {
    var weights: [Float]?
    var bias: Float = 0.0
    var iterations: Int = 0
    
    var batchEmbeddings: [[Float]] = []
    var batchLabels: [Float] = []

    private func getFileURL() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("ClassifierData.json")
    }

    init() {
        let url = getFileURL()
        if let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode(ClassifierData.self, from: data) {
            weights = decoded.weights
            bias = decoded.bias
            iterations = decoded.iterations
        }
    }

    func save() {
        let dataToSave = ClassifierData(weights: weights, bias: bias, iterations: iterations)
        if let encoded = try? JSONEncoder().encode(dataToSave) {
            try? encoded.write(to: getFileURL())
        }
    }

    func reset() {
        weights = nil
        bias = 0.0
        iterations = 0
        batchEmbeddings.removeAll()
        batchLabels.removeAll()
        try? FileManager.default.removeItem(at: getFileURL())
    }

    func predict(embedding: [Float]) -> Float {
        if weights == nil {
            weights = [Float](repeating: 0.0, count: embedding.count)
        }

        var dotProduct: Float = 0.0
        for i in embedding.indices {
            dotProduct += weights![i] * embedding[i]
        }
        dotProduct += bias

        return 1.0 / (1.0 + exp(-dotProduct))
    }

    func update(embedding: [Float], label: Float) {
        batchEmbeddings.append(embedding)
        batchLabels.append(label)
        
        if batchEmbeddings.count >= 10 {
            flushBatch()
        }
    }
    
    func flushBatch() {
        guard !batchEmbeddings.isEmpty else { return }
        
        let batchSize = Float(batchEmbeddings.count)
        let learningRate: Float = 0.01 / (1.0 + 0.001 * Float(iterations))
        
        var gradBias: Float = 0.0
        var gradWeights = [Float](repeating: 0.0, count: weights?.count ?? batchEmbeddings[0].count)
        
        for i in 0..<batchEmbeddings.count {
            let embedding = batchEmbeddings[i]
            let label = batchLabels[i]
            let prediction = predict(embedding: embedding)
            let error = prediction - label
            
            gradBias += error
            for j in embedding.indices {
                gradWeights[j] += error * embedding[j]
            }
        }
        
        bias -= learningRate * (gradBias / batchSize)
        if weights != nil {
            for j in weights!.indices {
                weights![j] -= learningRate * (gradWeights[j] / batchSize)
            }
        }
        
        iterations += 1
        
        batchEmbeddings.removeAll()
        batchLabels.removeAll()
        
        save()
    }
}
