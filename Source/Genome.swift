/// Represents the optimisation target used in the genetic algorithm.
///
/// Each case defines a different objective function the algorithm can optimise
/// against (e.g. distance minimisation vs fuel consumption).
///
/// Conforms to `CaseIterable` to allow iteration over all objectives
/// (useful for benchmarking and experiment sweeps).
enum OptimisationObjective: String, CaseIterable, CustomDebugStringConvertible {
    /// Total travel distance.
    case Distance
    /// Estimated fuel consumption.
    case Fuel
    var description: String {
        self.rawValue
    }
    var debugDescription: String {
        description
    }
}

//#MARK: - Truck
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

    mutating func AddCustomer(customer: Point, allCustomers: [Point], lut: [[Double]], capacity: Double, atIndex: Int? = nil) -> Bool {
        if self.CanAccept(customer: customer, capacity: capacity) {
            if let index = atIndex {
                self.sequence.insert(customer.id, at: index)
            }
            self.sequence.append(customer.id)
            self.demand += customer.demand
            self.centerOfMass = Truck.UpdateRepresentativePoint(sequence: Array(allCustomers.filter({self.sequence.contains($0.id)})))
            self.alphaRange = Truck.UpdateAlphaRange(sequence: self.sequence, lut: lut)
            return true
        }
        return false
    }

    /// Returns the representative point of the truck.
    ///
    /// Typically corresponds to the center of mass of all customers in the route.
    func representativePoint() -> (x: Double, y: Double) {
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
    
    func GetFitness(forObjective: OptimisationObjective) -> Double? {
        return self.scores[forObjective]
    }

    func GetDemand() -> Double {
        return self.demand
    }

    /// Returns a string identifier for the truck.
    ///
    /// Derived from the sequence of customer IDs.
    func GetID() -> String {
        return "\(self.sequence)"
    }

    /// Sets the evaluation scores for supported objectives.
    ///
    /// - Parameters:
    ///   - objective: Distance / Fuel objective to update the value.
    ///   - value: Fitness value of said objective.
    mutating func SetFitness(objective: OptimisationObjective, value: Double) {
        self.scores[objective] = value
    }

    func CanAccept(customer: Point, capacity: Double) -> Bool {
        return (customer.kind == .Customer && self.demand + customer.demand <= capacity)
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

    /// Mutates the sequence, asserts that the customers in being served by the truck did 
    /// not change, but the sequnce in which they are served did.
    /// 
    /// A lite version of mutation function, that does not update any hyper-parameter, since the 
    /// customer set is expected to remain same, best used for intra-vehicular optimisation like 
    /// rotate-left, reversed, or 2-3 opt mutator.
    mutating func MutateSequence(newSequence: [Int]) {
        assert("\(self.sequence.sorted())" == "\(newSequence.sorted())", "Expected no change in the customers being served by truck.")
        self.sequence = newSequence
    }
}

//#MARK: - Routine
/// Represents a collection of `Truck` objects evaluated together as a candidate
/// solution in a multi-objective optimization process.
///
/// A `Routine` aggregates multiple trucks and evaluates their combined fitness
/// across all `OptimisationObjective` cases. It also stores metadata used for
/// Pareto front ranking, such as dominance relationships.
struct Routine {
    
    /// The trucks that make up this routine.
    private var trucks: [Truck]
    
    /// A parameter controlling evaluation strictness.
    /// Defaults to `1.0`.
    private var strictness: Double
    
    /// Indices of routines that this routine dominates.
    var dominatesSetIndex = [Int]()
    
    /// The number of routines that dominate this routine.
    var dominatedBy = 0
    
    /// The Pareto front rank of this routine.
    /// Lower values indicate better fronts (e.g., `0` is the best front).
    var frontNumber = 0
    
    public var description : String {
        "Routine (strictness: \(self.strictness), fitness: \(self.GetFitness())):\n\t\(self.trucks.map({"\($0.GetSequence()) with demand \($0.GetDemand())"}).joined(separator: "\n\t"))"
    }
    /// Creates a new routine with the given trucks.
    ///
    /// - Parameter trucks: An array of `Truck` instances to include in the routine.
    init(trucks: [Truck]) {
        self.trucks = trucks
        self.strictness = 1.0
    }
    
    /// Returns a unique identifier for the routine.
    ///
    /// The identifier is constructed by concatenating the IDs of all trucks,
    /// separated by commas.
    ///
    /// - Returns: A string representing the combined truck IDs.
    func GetID() -> String {
        self.trucks.map { $0.GetID() }.joined(separator: ",")
    }
    
    /// Returns the trucks in this routine as an enumerated sequence.
    ///
    /// Each element in the sequence contains the index and the corresponding `Truck`.
    ///
    /// - Returns: An enumerated sequence of trucks.
    func GetTrucks() -> EnumeratedSequence<[Truck]> {
        trucks.enumerated()
    }
    
    /// Replaces the truck at the specified index.
    ///
    /// - Parameters:
    ///   - index: The index of the truck to replace.
    ///   - truck: The new `Truck` to insert at the specified index.
    mutating func SetTruck(at index: Int, to truck: Truck) {
        trucks[index] = truck
    }

    mutating func UpdateStrictness(upperBound: Double) -> Double {
        if let strictness = try? Double.RandomNumber(center: self.strictness, upperBound: upperBound) {
            self.strictness = strictness
        }
        return strictness
    }

    mutating func SetStrictness(strictness: Double) {
        self.strictness = strictness
    }

    mutating func GetStrictness() -> Double {
        return self.strictness
    }

    mutating func SetTruckFitness(indexed: Int, objective: OptimisationObjective, value: Double) {
        self.trucks[indexed].SetFitness(objective: objective, value: value)
    }

    mutating func SetTruckSequence(indexed: Int, sequence: [Point], lut: [[Double]], capacity: Double) {
        self.trucks[indexed].SetSequence(sequence: sequence, lut: lut, capacity: capacity)
    }

    mutating func MutateTruckSequence(indexed: Int, newSequence: [Int]) {
        self.trucks[indexed].MutateSequence(newSequence: newSequence)
    }

    mutating func GetAlphaforTruck(indexed: Int) -> Double {
        return self.trucks[indexed].GetAlpha()
    }
    
    /// Calculates the aggregated fitness of the routine across all objectives.
    ///
    /// Iterates over all cases of `OptimisationObjective` and sums the fitness
    /// values of each truck for each objective.
    ///
    /// - Returns: A dictionary mapping each `OptimisationObjective` to its total fitness value.
    ///
    /// - Important: This method force unwraps the result of
    ///   `Truck.GetFitness(forObjective:)`. Ensure that method never returns `nil`
    ///   to avoid runtime crashes.
    func GetFitness() -> [OptimisationObjective: Double] {
        var fitness = [OptimisationObjective: Double]()
        
        for objective in OptimisationObjective.allCases {
            for truck in trucks {
                fitness[objective, default: 0] += truck.GetFitness(forObjective: objective) ?? 0
            }
        }
        return fitness
    }
}
