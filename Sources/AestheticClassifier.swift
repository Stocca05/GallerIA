import Foundation

class AestheticClassifier {
    var weights: [Float]?
    var bias: Float = 0.0

    init() {
        weights = UserDefaults.standard.array(forKey: "gallerIA_weights") as? [Float]
        bias = UserDefaults.standard.float(forKey: "gallerIA_bias")
    }

    func save() {
        UserDefaults.standard.set(weights, forKey: "gallerIA_weights")
        UserDefaults.standard.set(bias, forKey: "gallerIA_bias")
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
        let prediction = predict(embedding: embedding)
        let error = prediction - label
        let learningRate: Float = 0.01

        bias -= learningRate * error
        for i in embedding.indices {
            weights?[i] -= learningRate * error * embedding[i]
        }
        save()
    }
}
