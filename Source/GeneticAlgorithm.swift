import Foundation
///Base Genetic Algorithm, doesn't do anything, but is a colection of mutations and private
/// supporting functions.
/// 
/// 
class GeneticAlgorithm {
    // Configuration parameters
    private let benchmark : Benchmark
    private let iterations: Int
    private let populationCount : Int
    
    // LUTs
    private let distanceMatrix: [[Double]]
    private let Depot : Point
    private let Customers : Dictionary<Int, Point>

    //Runtime Variables.
    private var parentPopulation = [Routine]()
    private var offspringPopulation = [Routine]()

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
    func InitialisePopulation() -> [Routine] {
        var attempts = 0
        while self.offspringPopulation.count < self.populationCount {
            if let individual = self.initialiseIndividual() {
                self.offspringPopulation.append(individual)
                attempts += 1
            }
        }
        return self.offspringPopulation
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

    func EvaluatePopulation() {
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
    

    func IntraVehicularMutation(individual: Routine, strictness: Double) -> Routine {
        var mutableIndividual = individual
        mutableIndividual.SetStrictness(strictness: strictness)
        
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
            
            if let (end, _) = SpinRouletteWheel(strictness: strictness, onCandidates: candidates) {
                sequence[start...end].reverse()
            } else {
                sequence = _rotateLeft(sequence: sequence)
            }

        case 0.5..<0.7:
            sequence = _swap(sequence: sequence)

        case 0.7..<0.85:
            sequence = _rotateLeft(sequence: sequence)

        default:
            sequence = _reversed(sequence: sequence)
        }

        mutableIndividual.MutateTruckSequence(indexed: index, newSequence: sequence)
        return mutableIndividual
    }

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
    
    func Crossover(parent1: Routine, parent2: Routine) -> Routine {
    print("Crossover")
    print(parent1)
    print(" + ")
    print(parent2)
    print("--------------------------------")

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

    // --- Repair Phase ---
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

    // --- Final validation ---
    let allCustomers = returnRoutine.GetTrucks().flatMap { $0.element.GetSequence() }

    if Set(allCustomers).count == self.Customers.count {
        print(returnRoutine)
        return returnRoutine
    }

    print("Invalid offspring — falling back")
    return Bool.random() ? parent1 : parent2
}
    







    //#MARK: - DEBUG
    public func GetOffspring() -> [Routine] {
        return self.offspringPopulation
    }
}


