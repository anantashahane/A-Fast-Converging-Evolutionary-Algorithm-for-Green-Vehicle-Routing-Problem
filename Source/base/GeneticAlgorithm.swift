import Foundation

//#MARK: - Genetic Algorithm Scafolding.
///Base Genetic Algorithm, doesn't do anything, but is a colection of mutations and private
/// supporting functions.
/// 
/// 
class GeneticAlgorithm {
    // Configuration parameters
    internal let benchmark : Benchmark
    internal let iterations: Int
    internal let populationCount : Int
    
    // LUTs
    private let distanceMatrix: [[Double]]
    private let Depot : Point
    private let Customers : Dictionary<Int, Point>

    //Runtime Variables.
    internal var parentPopulation = [Routine]()
    internal var offspringPopulation = [Routine]()

    init(benchmark: Benchmark, populationCount: Int, iterations: Int) {
        self.benchmark = benchmark
        self.populationCount = populationCount
        self.iterations = iterations
        self.Customers = Dictionary(
            uniqueKeysWithValues: benchmark.points
                .filter { $0.kind == .Customer }
                .map { ($0.id, $0) }
        )
        self.Depot = benchmark.points.filter({$0.kind == .Depot})[0]

        self.distanceMatrix = BuildDistanceMatrix(from: benchmark)
    }

    // #MARK: - Initialisation
    func InitialisePopulation() {
        var attempts = 0
        while self.parentPopulation.count < self.populationCount {
            if let individual = self.initialiseIndividual(strictness: (100 * Double(self.offspringPopulation.count) / Double(populationCount))) {
                self.parentPopulation.append(individual)
                attempts += 1
            }
        }
    }

    private func initialiseIndividual(strictness: Double = 100) -> Routine? {
        var trucks = [Truck]()
        var remainingCustomers = Array(self.Customers.values)
        for _ in 0..<self.benchmark.trucks {
            var truck = Truck(sequence: [], lut: distanceMatrix, capacity: self.benchmark.capacity)
            var acceptableCustomer = remainingCustomers.filter({truck.CanAccept(customer: $0, capacity: self.benchmark.capacity)})
            if let randomCustomer = acceptableCustomer.randomElement() {
                if truck.AddCustomer(customer: randomCustomer, allCustomers: Array(self.Customers.values), lut: self.distanceMatrix, capacity: self.benchmark.capacity) {
                    remainingCustomers = remainingCustomers.filter({$0.id != randomCustomer.id})
                }
            }
            acceptableCustomer = remainingCustomers.filter({truck.CanAccept(customer: $0, capacity: self.benchmark.capacity)})
            var lastCustomer = self.Depot
            while (!acceptableCustomer.isEmpty) {
                acceptableCustomer = acceptableCustomer.sorted(by: {
                    DotProduct(source: $0, target: lastCustomer, anchor: self.Depot) > DotProduct(source: $1, target: lastCustomer, anchor: self.Depot)
                })
                if let candidateCustomer = SpinRouletteWheel(strictness: strictness, onCandidates: acceptableCustomer) {
                    if truck.AddCustomer(customer: candidateCustomer, allCustomers: Array(self.Customers.values), lut: self.distanceMatrix, capacity: self.benchmark.capacity) {
                        remainingCustomers = remainingCustomers.filter({$0.id != candidateCustomer.id})
                    }
                    lastCustomer = candidateCustomer
                }
                acceptableCustomer = remainingCustomers.filter({truck.CanAccept(customer: $0, capacity: self.benchmark.capacity)})

            }
            trucks.append(truck)
        }
        if remainingCustomers.isEmpty {
            return Routine(trucks: trucks)
        }
        return nil
    }

    //MARK: - Evaluation
    private func EvaluateIndividualDistance(individual: inout Routine) {
        for (tid, truck) in individual.GetTrucks() {
            var previous = self.Depot.id
            var distance = 0.0
            for servicePoint in truck.GetSequence() {
                distance += self.distanceMatrix[previous][servicePoint]
                previous = servicePoint
            }
            distance += self.distanceMatrix[previous][self.Depot.id]
            individual.SetTruckFitness(indexed: tid, objective: .Distance, value: distance)
        }
    }

    private func EvaluateIndividualFuel(individual: inout Routine) {
        for (tid, truck) in individual.GetTrucks() {
            var previous = self.Depot.id
            var fuel = 0.0
            var remainingDemand = truck.GetDemand()
            for servicePoint in truck.GetSequence() {
                fuel += ((1 + (remainingDemand / self.benchmark.capacity)) * distanceMatrix[previous][servicePoint])
                remainingDemand -= (self.Customers[servicePoint]?.demand ?? 0)
                previous = servicePoint
            }
            fuel += distanceMatrix[previous][self.Depot.id]
            individual.SetTruckFitness(indexed: tid, objective: .Fuel, value: fuel)
        }
    }

    func EvaluatePopulation(parent: Bool = false) {
        if parent {
            for index in 0..<self.parentPopulation.count {
                self.EvaluateIndividualDistance(individual: &parentPopulation[index])
                self.EvaluateIndividualFuel(individual: &parentPopulation[index])
            }
            return
        }
        for index in 0..<self.offspringPopulation.count {
            self.EvaluateIndividualDistance(individual: &offspringPopulation[index])
            self.EvaluateIndividualFuel(individual: &offspringPopulation[index])
        }
    }

    //#MARK: - Mutations
    private func _reversed(sequence: [Int]) -> [Int] {
        return Array(sequence.reversed())
    }

    private func _rotateLeft(sequence: [Int]) -> [Int] {
        guard sequence.count > 2 else { return sequence }
        let pivot = Int.random(in: 1..<(sequence.count - 1))
        return Array(sequence[pivot...] + sequence[..<pivot])
    }

    private func _swap(sequence: [Int]) -> [Int] {
        guard sequence.count > 1 else { return sequence }
        var seq = sequence
        let i = Int.random(in: 0..<seq.count)
        var j = Int.random(in: 0..<seq.count)
        while i == j {
            j = Int.random(in: 0..<seq.count)
        }
        seq.swapAt(i, j)
        return seq
    }
    

    func IntraVehicularMutation(individual: Routine, strictness: Double? = nil) -> Routine {
        var mutableIndividual = individual
        if let strictness = strictness {
            mutableIndividual.SetStrictness(strictness: strictness)
        } else {
            _ = mutableIndividual.UpdateStrictness(upperBound: Double(self.benchmark.points.count))
        }
        
        guard let (index, truck) = individual.GetTrucks().randomElement() else {
            return individual
        }
        
        var sequence = truck.GetSequence()

        if sequence.count < 4 {
            let roll = Double.random(in: 0...1)
            
            if sequence.count < 3 {
                sequence = _reversed(sequence: sequence)
            } else {
                if roll < 0.5 {
                    sequence = _reversed(sequence: sequence)
                } else {
                    sequence = _rotateLeft(sequence: sequence)
                }
            }
            
            mutableIndividual.MutateTruckSequence(indexed: index, newSequence: sequence)
            return mutableIndividual
        }

        let chance = Double.random(in: 0...1)

        switch chance {
        case 0..<0.5:
            let start = Int.random(in: 0..<(sequence.count - 2))
            let alpha = mutableIndividual.GetAlphaforTruck(indexed: index)
            
            let baseLength = distanceMatrix[sequence[start]][sequence[start + 1]]
            let searchParameter = alpha * baseLength
            
            let candidates = sequence.enumerated().filter {
                $0.offset > start &&
                distanceMatrix[sequence[start]][$0.element] <= searchParameter
            }
            
            if let (end, _) = SpinRouletteWheel(strictness: mutableIndividual.GetStrictness(), onCandidates: candidates) {
                sequence[start...end].reverse()
            } else {
                sequence = _rotateLeft(sequence: sequence)
            }

        case 0.5..<0.7: sequence = _swap(sequence: sequence)
        case 0.7..<0.85: sequence = _rotateLeft(sequence: sequence)
        default: sequence = _reversed(sequence: sequence)
        }

        mutableIndividual.MutateTruckSequence(indexed: index, newSequence: sequence)
        return mutableIndividual
    }

    /// Computes a ranked list of candidate insertion positions for a given customer into a routing solution.
    ///
    /// This function evaluates all possible insertion points across all (broken) trucks in a given `Routine`,
    /// filtering only those trucks that can feasibly accommodate the customer based on capacity constraints.
    /// Each candidate insertion is scored using a dot product heuristic that measures spatial or cost efficiency
    /// relative to the depot and existing route structure.
    ///
    /// Two types of insertion positions are considered:
    /// - Insertion into empty trucks (no existing route).
    /// - Insertion between consecutive customers in existing routes.
    ///
    /// - Parameters:
    ///   - source: The customer `Point` to be inserted into the routing solution.
    ///   - individual: The current routing solution containing upto `benchmark.trucks` number of trucks.
    ///
    /// - Returns: A list of candidate insertion options, each contains named tuples with names:
    ///   - `truck`: The index of the truck considered.
    ///   - `customer?`: The existing customer after which insertion is evaluated (nil for empty trucks).
    ///   - `cid?`: The position index within the truck route (nil for empty trucks).
    ///   - `dotProduct`: Heuristic score representing insertion quality (higher is better).
    ///
    /// - Complexity: O(n × m), where n is the number of trucks and m is the average route length.
    private func getRepairCandidates(forInserting source: Point, into individual: Routine) -> [(truck: Int, customer: Int?, cid: Int?, dotProduct: Double)] {
        var data = [(truck: Int, customer: Int?, cid: Int?, dotProduct: Double)]()
        for (tid, truck) in individual.GetTrucks() where truck.CanAccept(customer: source, capacity: self.benchmark.capacity) {
            if truck.GetSequence().isEmpty {
                let dotProduct = DotProduct(source: source, target: truck, anchor: self.Depot)
                data.append((truck: tid, customer: nil, cid: nil, dotProduct))
            }
            for (cid, customer) in truck.GetSequence().enumerated() {
                let dotProduct = DotProduct(source: source, target: self.Customers[customer]!, anchor: self.Depot)
                data.append((truck: tid, customer: customer, cid: cid, dotProduct: dotProduct))
            }
        }
        return data
    }

    /// Performs a Large Neighborhood Search (LNS) optimization on a given routing solution.
    ///
    /// This method applies a two-phase heuristic:
    /// - **Destruction phase**: randomly removes a subset of customers from the current solution based on a destruction probability.
    /// - **Repair phase**: reinserts removed customers into the solution using a dot product based smart repair operation.
    ///
    /// The repair process evaluates multiple insertion positions across all trucks, ranking candidates by a heuristic score and selecting 
    /// insertions using a roulette wheel strategy controlled by a strictness parameter.
    ///
    /// If all removed customers are successfully reinserted, the method updates the solution's strictness and returns the improved routine. 
    /// Otherwise, it falls back to the original individual.
    ///
    /// - Parameters:
    ///   - individual: The initial routing solution to be optimized.
    ///   - strictness: Controls the selectiveness of the repair phase; higher values favor better-scoring insertions.
    ///   - destructionProbability: Probability of removing each customer during the destruction phase (default is `0.3`).
    ///
    /// - Returns: A new `Routine` representing the optimized solution, or the original individual if repair fails.
    ///
    /// - Note: This method assumes all customers referenced in the routine exist in `self.Customers`.
    func LNS(individual: Routine, strictness: Double, destructionProbability: Double=0.3) -> Routine {
        var mutableIndividual = individual
        // Destruction phase.
        var removedCustomers = [Int]()
        for (index, vehicle) in mutableIndividual.GetTrucks() {
            let sequence = vehicle.GetSequence()
            var destroyedSequence = [Int]()
            for individual in sequence {
                if Double.random(in: 0...1) > destructionProbability {
                    destroyedSequence.append(individual)
                } else {
                    removedCustomers.append(individual)
                }
            }
            mutableIndividual.SetTruckSequence(indexed: index, sequence: destroyedSequence.map({self.Customers[$0]!}), lut: self.distanceMatrix, capacity: self.benchmark.capacity)
        }
        // Repair phase:
        removedCustomers.shuffle()
        var remaining = [Int]()
        for customer in removedCustomers {
            let point = self.Customers[customer]!
            let candidateList = getRepairCandidates(forInserting: point, into: mutableIndividual).sorted(by: {$0.dotProduct > $1.dotProduct})
            if let candidate = SpinRouletteWheel(strictness: strictness, onCandidates: candidateList) {
                let _ = mutableIndividual.AddCustomer(in: candidate.truck, customer: point, allCustomers: Array(Customers.values), 
                lut: self.distanceMatrix, capacity:self.benchmark.capacity, atIndex: candidate.cid)
            } else {
                remaining.append(customer)
            }
        }
        if remaining.isEmpty {
            mutableIndividual.SetStrictness(strictness: strictness)
            return mutableIndividual
        }
        return individual
    }

    // #MARK: - Crossover
    private func countRepeatingCustomers(in truck: Truck, assignedCustomers: [Int]) -> Int {
        return truck.GetSequence().filter({assignedCustomers.contains($0) }).count
    }
    
    /// Performs crossover between two parent routing solutions to generate a new offspring solution.
    ///
    /// This genetic operator combines structural elements from two parents. 
    /// Prior to crossover, the parent population should be randomly shuffled so that crossover is 
    /// performed on non-deterministic adjacent pairs, improving genetic diversity.
    ///
    /// ### Phase 1: Random inheritance from parent1
    /// A subset of trucks is randomly selected from `parent1`. Their customer sequences are filtered
    /// to avoid duplicates and directly inserted into the offspring.
    ///
    /// ### Phase 2: Complementary inheritance from parent2
    /// Remaining trucks are selected from `parent2`, prioritized by how few conflicts they introduce
    /// with already assigned customers. Only non-duplicated customers are retained.
    ///
    /// ### Repair Phase
    /// Any missing customers are reinserted using a heuristic candidate selection process combined with
    /// a roulette-wheel selection strategy. The strictness parameter is averaged from both parents
    /// to balance exploration and exploitation.
    ///
    /// ### Validation
    /// The resulting offspring is validated to ensure all customers are present exactly once.
    /// If validation fails, one of the parents is returned as a fallback.
    ///
    /// - Parameters:
    ///   - parent1: First parent solution.
    ///   - parent2: Second parent solution.
    ///
    /// - Returns: A new `Routine` representing the offspring, or one of the parents if validity fails.
    ///
    /// - Important: The method assumes route feasibility is enforced through `AddCustomer` and truck capacity constraints.
    private func Crossover(parent1: Routine, parent2: Routine) -> Routine {
        let split = Int.random(in: 1...(self.benchmark.trucks / 2))
        var assignedCustomers = Set<Int>()
        var crossOverTrucks = [Truck]()

        // --- Phase 1: take random trucks from parent1 ---
        var p1Trucks: [Truck] = parent1.GetTrucks().map(\.element)
        p1Trucks.shuffle()

        for _ in 0..<split {
            guard let truck = p1Trucks.popLast() else { break }

            let uniqueSeq = truck.GetSequence().filter {
                assignedCustomers.insert($0).inserted
            }

            let points = uniqueSeq.map { self.Customers[$0]! }
            let newTruck = Truck(sequence: points, lut: distanceMatrix, capacity: self.benchmark.capacity)

            crossOverTrucks.append(newTruck)
        }

        // --- Phase 2: fill from parent2 ---
        let p2Trucks = parent2.GetTrucks().sorted {
            countRepeatingCustomers(in: $0.element, assignedCustomers: Array(assignedCustomers)) <
            countRepeatingCustomers(in: $1.element, assignedCustomers: Array(assignedCustomers))
        }

        for i in 0..<(self.benchmark.trucks - split) {
            let sequence = p2Trucks[i].element.GetSequence().filter {
                assignedCustomers.insert($0).inserted
            }

            let points = sequence.map { self.Customers[$0]! }
            let truck = Truck(sequence: points, lut: distanceMatrix, capacity: self.benchmark.capacity)

            crossOverTrucks.append(truck)
        }

        // ---Phase 3: Repair Phase ---
        let strictness = (parent1.GetStrictness() + parent2.GetStrictness()) / 2
        var returnRoutine = Routine(trucks: crossOverTrucks, strictness: strictness)

        let remainingCustomers = self.Customers.keys.filter { !assignedCustomers.contains($0) }
        for customer in remainingCustomers {
            let point = Customers[customer]!
            let candidates = getRepairCandidates(forInserting: point, into: returnRoutine)

            if let candidate = SpinRouletteWheel(strictness: strictness, onCandidates: candidates) {
                assignedCustomers.insert(customer)

                _ = returnRoutine.AddCustomer(
                    in: candidate.truck,
                    customer: point,
                    allCustomers: Array(self.Customers.values),
                    lut: distanceMatrix,
                    capacity: self.benchmark.capacity,
                    atIndex: candidate.cid
                )
            }
        }
        let allCustomers = returnRoutine.GetTrucks().flatMap { $0.element.GetSequence() }
        if Set(allCustomers).count == self.Customers.count {
            return returnRoutine
        }
        return Bool.random() ? parent1 : parent2
    }

    func Crossover() {
        self.parentPopulation.shuffle()
        self.offspringPopulation = []
        for i in 0..<self.parentPopulation.count {
            let crossoverIndividual = Crossover(parent1: self.parentPopulation[i], parent2: self.parentPopulation[(i + 1) % self.parentPopulation.count])
            self.offspringPopulation.append(crossoverIndividual)
        }
    }

    //#MARK: - Selection (NSGA-II)
    private func FastNonDominatedSort() -> [[Routine]] {
        var population = self.parentPopulation + self.offspringPopulation
        var front = [Routine]()
        var fronts = [[Routine]]()
        for pid in 0..<population.count {
            population[pid].dominatedByCount = 0
            population[pid].dominatesSetIndex = []
            for qid in 0..<population.count {
                if population[pid] < population[qid] {
                    population[pid].dominatesSetIndex.append(qid)
                } else if population[qid] < population[pid] {
                    population[pid].dominatedByCount += 1
                }
            }
            if population[pid].dominatedByCount == 0 {
                population[pid].rank = 1
                population[pid].frontNumber = 1
                front.append(population[pid])
            }
        }

        var i = 0
        fronts.append(front)
        while !fronts[i].isEmpty {
            front = []
            for pid in 0..<fronts[i].count {
                for qid in fronts[i][pid].dominatesSetIndex {
                    population[qid].dominatedByCount -= 1
                    if population[qid].dominatedByCount == 0 {
                        population[qid].rank = i + 2
                        front.append(population[qid])
                    }
                }
            }
            i += 1
            for j in 0..<front.count {
                front[j].frontNumber += 1
            }
            fronts.append(front)
        }
        return fronts
    }

    private func CrowdingDistance(front: [Routine]) -> [Routine] {
        if front.count <= 1 { 
            return front 
        }
        var pop = front.map { (individual: $0, distance: 0.0) }
        let length = front.count
        let objectives = OptimisationObjective.allCases
        for key in objectives {
            let maxVal = front.map { $0.GetFitness(for: key)}.max() ?? -1.0
            let minVal = front.map { $0.GetFitness(for: key)}.min() ?? -1.0

            guard (maxVal != minVal && maxVal > 0 && minVal > 0) else { continue }

            pop.sort { $0.individual.GetFitness(for: key) < $1.individual.GetFitness(for: key) }

            pop[0].distance = Double.infinity
            pop[length - 1].distance = Double.infinity

            for i in 1..<length - 1 {
                let prev = pop[i - 1].individual.GetFitness(for: key)
                let next = pop[i + 1].individual.GetFitness(for: key)
                pop[i].distance += (next - prev) / (maxVal - minVal)
            }
        }

        return pop.sorted(by: { $0.distance > $1.distance }).map({ $0.individual })
    }

    /// Performs the selection step of the NSGA-II algorithm.
    ///
    /// This method combines the current parent and offspring populations,
    /// then applies non-dominated sorting to rank solutions into Pareto fronts.
    /// Within each front, individuals are ordered using crowding distance
    /// to preserve diversity.
    ///
    /// The next generation is formed by selecting the best individuals
    /// based on rank and crowding distance until the population size is met.
    ///
    /// - Important: Fitness values must already be evaluated for all
    ///   individuals in both the parent and offspring populations
    ///   before calling this method.
func Selection() {
        let fronts = FastNonDominatedSort()
        var remainingPopulationSize = self.populationCount
        parentPopulation = []
        var finalFront = [Routine]()
        for front in fronts {
            if remainingPopulationSize - front.count > 0 {
                remainingPopulationSize -= front.count
                parentPopulation += front
            } else {
                finalFront = front
                break
            }
        }
        let population = CrowdingDistance(front: finalFront)
        parentPopulation += population[0..<remainingPopulationSize]
    }

    //#MARK: - DEBUG
    public func GetOffspring() -> [Routine] {
        return self.offspringPopulation
    }
}