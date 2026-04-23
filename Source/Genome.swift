/// Represents the optimisation target used in the genetic algorithm.
///
/// Each case defines a different objective function the algorithm can optimise
/// against (e.g. distance minimisation vs fuel consumption).
///
/// Conforms to `CaseIterable` to allow iteration over all objectives
/// (useful for benchmarking and experiment sweeps).
enum OptimisationObjective: String, CaseIterable {
    /// Total travel distance.
    case Distance
    /// Estimated fuel consumption.
    case Fuel
}

//#MARK:- Truck
struct Truck: PointRepresentable {
    /// Ordered sequence of customer IDs representing the route.
    ///
    /// - Note: Must only contain customer IDs. Depot is excluded.
    private var sequence: [Int]

    /// Exploitation/exploration balance parameter used in optimisation heuristics.
    private var alpha: Double
    /// Valid range for alpha based on intra-route distance structure.
    private var alphaRange: (min: Double, max: Double)
    /// Total demand of all customers in the route.
    private var demand: Double
    /// Representative spatial position of the truck’s route.
    ///
    /// Typically computed as a center of mass of customer positions.
    private var centerOfMass: (x: Double, y: Double)
    /// Evaluation scores for different optimisation objectives.
    private var scores: Dictionary<OptimisationObjective, Double>

    /// Creates a truck from a sequence of points.
    ///
    /// - Parameters:
    ///   - sequence: Ordered list of points (must only include customers).
    ///   - lut: Distance lookup table used for heuristic computation.
    ///   - capacity: Maximum allowed demand for the truck.
    init(sequence: [Point], lut: [[Double]], capacity: Double) {
        let sequenceID = sequence.map { $0.id }
        self.sequence = sequenceID
        self.alpha = 1.0
        self.demand = sequence.map({ $0.demand }).reduce(0, +)
        self.alphaRange = Truck.UpdateAlphaRange(sequence: sequenceID, lut: lut)
        self.centerOfMass = Truck.UpdateRepresentativePoint(sequence: sequence)
        self.scores = [:]
        assert(self.demand <= capacity, "Capacity exceeded for truck: \(self.sequence)@\(self.demand), expected \(capacity)")
    }

    private static func UpdateAlphaRange(sequence: [Int], lut: [[Double]]) -> (min: Double, max: Double) {
        if sequence.count <= 2 {
            return (min: 1, max: 1)
        }
        var minVal: Double? = nil
        var maxVal: Double? = nil
        for point1 in sequence {
            for point2 in sequence where point1 != point2 {
                let dist = lut[point1][point2] 
                minVal = min(minVal ?? dist, dist)
                maxVal = max(maxVal ?? dist, dist)
            }
        }
        if let minVal = minVal, let maxVal = maxVal {
            return (min: minVal / maxVal, max: maxVal / minVal)
        }
        return (min: 1, max: 1)
    }

    private static func UpdateRepresentativePoint(sequence: [Point]) -> (x: Double, y: Double) {
        let x = sequence.map({ $0.demand * $0.x }).reduce(0, +)
        let y = sequence.map({ $0.demand * $0.y }).reduce(0, +)
        let demand = sequence.map({ $0.demand }).reduce(0, +)
        return (x: x / demand, y: y / demand)
    }

    /// Updates the internal route of the truck.
    ///
    /// Recomputes:
    /// - demand
    /// - alpha range
    /// - representative point
    /// 
    /// Resets:
    /// - objective scores
    mutating func SetSequence(sequence: [Point], lut: [[Double]], capacity: Double) {
        let sequenceID = sequence.map { $0.id }
        self.sequence = sequenceID
        self.demand = sequence.map({ $0.demand }).reduce(0, +)
        self.alphaRange = Truck.UpdateAlphaRange(sequence: sequenceID, lut: lut)
        self.centerOfMass = Truck.UpdateRepresentativePoint(sequence: sequence)
        self.scores = [:]
        assert(self.demand <= capacity, "Capacity exceeded for truck: \(self.sequence)@\(self.demand), expected \(capacity)")
    }
    
    /// Returns the current route as an ordered list of customer IDs.
    func GetSequence() -> [Int] {
        return sequence
    }

    /// Returns the representative point of the truck.
    ///
    /// Typically corresponds to the center of mass of all customers in the route.
    func representivePoint() -> (x: Double, y: Double) {
        return self.centerOfMass
    }

    /// Returns the fitness vector across all optimisation objectives.
    ///
    /// The order of values matches `OptimisationObjective.allCases`.
    /// `NOTE:` Missing scores are skipped.
    func GetFitnessVector() -> [Double] {
        var vector = [Double]()
        for type in OptimisationObjective.allCases {
            if let score = self.scores[type] {
                vector.append(score)
            }
        }
        return vector
    }

    /// Returns a string identifier for the truck.
    ///
    /// Derived from the sequence of customer IDs.
    func getID() -> String {
        return "\(self.sequence)"
    }

    /// Sets the evaluation scores for supported objectives.
    ///
    /// - Parameters:
    ///   - distance: Distance covered during route traversal.
    ///   - fuel: Fuel consumpted during route traversal.
    mutating func SetScores(distance: Double, fuel: Double) {
        self.scores = [.Distance: distance, .Fuel: fuel]
    }

    // Updates and returns the current alpha value.
    ///
    /// Alpha is randomly sampled within `alphaRange`. If the current alpha
    /// lies within the valid range, it is smoothed with the new sample.
    ///
    /// - Returns: Updated alpha value.
    mutating func GetAlpha() -> Double {
        let newAlpha = Double.random(in: self.alphaRange.min...self.alphaRange.max)
        if (self.alphaRange.min...self.alphaRange.max).contains(self.alpha) {
            self.alpha = (newAlpha * 0.2) + (self.alpha * 0.8)
        } else {
            self.alpha = newAlpha
        }
        return self.alpha
    }
}