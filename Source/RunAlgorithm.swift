import Foundation

extension GeneticAlgorithm : Runnable {
    func MutatePopulation() {
        for (index, individual) in self.offspringPopulation.enumerated() {
            switch Double.random(in: 0...1) {
                case ...0.3: offspringPopulation[index]  = IntraVehicularMutation(individual: individual)
                default: offspringPopulation[index] = LNS(individual: individual, strictness: 10, destructionProbability: Double.random(in: 0.1...0.6))
            }
        }
    }

    func run() -> [Routine] {
        // print("Initialise")
        InitialisePopulation()
        // print("Evaluate parent")
        EvaluatePopulation(parent: true)
        for index in 1...self.iterations {
            // print("Crossover \(index)")
            Crossover()
            // print("Mutate \(index)")
            MutatePopulation()
            // print("Evaluate \(index)")
            EvaluatePopulation()
            // print("Selection \(index)")
            Selection()
            let minDistance = self.parentPopulation.map({$0.GetFitness(for: .Distance)}).min()!
            let minFuel = self.parentPopulation.map({$0.GetFitness(for: .Fuel)}).min()!
            print("Gen \(index) (\((minDistance * 100 / self.benchmark.optimality) - 100)% conv.): Optimal Dist: \(self.benchmark.optimality), front: [\(minDistance) km, \(minFuel) l].")
        }
        return self.parentPopulation
    }
}