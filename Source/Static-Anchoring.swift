import Foundation

extension GeneticAlgorithm : Runnable {

    func CalculateStrictness(for individual: Routine) -> Routine {
        let frontSize = Double(self.fronts.count)
        var strictness = (Double(individual.frontNumber) * Double(self.benchmark.points.count) * pow(2.71, Double.NormalRandom(mu: 0, sigma: 2)))
        strictness *= (Double(self.iterations - self.generation) / frontSize)
        var returnIndividual = individual
        // print(strictness, terminator:"\t")

        returnIndividual.SetStrictness(strictness: strictness)
        return returnIndividual
    }

    func MutatePopulation() {
        for (index, individual) in self.offspringPopulation.enumerated() {
            switch Double.random(in: 0...1) {
                case ...0.3: offspringPopulation[index]  = IntraVehicularMutation(individual: individual)
                default: let destructionProbability = Double.random(in: 0.1...0.6)
                offspringPopulation[index] = LNS(individual: individual, destructionProbability: destructionProbability, dynamicAnchoring: false)
            }
        }
    }

    func run() -> (history: [Routine], front: [Routine])  {
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
            self.parentPopulation = self.parentPopulation.map({self.CalculateStrictness(for: $0)})
            let minDistance = self.parentPopulation.map({$0.GetFitness(for: .Distance)}).min()!
            let minFuel = self.parentPopulation.map({$0.GetFitness(for: .Fuel)}).min()!
            print("Gen \(index) (\((minDistance * 100 / self.benchmark.optimality) - 100)% conv.): Optimal Dist: \(self.benchmark.optimality), front: [\(minDistance) km, \(minFuel) l], ", terminator: "")
            print(" Unique parents: \(Set(self.parentPopulation.map({$0.GetID()})).count), Unique Children: \(Set(self.offspringPopulation.map({$0.GetID()})).count))")
        }
        let front = Array(
            Dictionary(self.fronts[0].map { ($0.GetID(), $0) },
                    uniquingKeysWith: { first, _ in first }
            ).values
        )
        return (history: self.history, front: front)
    }
}