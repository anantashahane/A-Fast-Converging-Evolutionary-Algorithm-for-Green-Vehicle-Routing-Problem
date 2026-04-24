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
        print("Parent population: \(self.parentPopulation.count), attempts: \(attempts).")
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

    func EvaluatePopulation() {
        for index in 0..<self.offspringPopulation.count {
            self.EvaluateIndividualDistance(individual: &offspringPopulation[index])
        }
    }

    //#MARK: - DEBUG
    public func GetOffspring() -> [Routine] {
        return self.offspringPopulation
    }
}


