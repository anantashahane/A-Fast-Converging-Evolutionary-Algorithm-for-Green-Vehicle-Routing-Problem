import Foundation


func main() {
    let clock = ContinuousClock()
    var ga : GeneticAlgorithm? = nil
    let time = clock.measure{
        if let benchmark = ReadFile(filePath: "Benchmarks/A-n32-k5.json") {
            ga = GeneticAlgorithm(benchmark: benchmark, populationCount: 100, iterations: 5000)
        }
    }
    if let ga = ga {
        ga.InitialisePopulation()
        ga.EvaluatePopulation()
        let population = ga.GetOffspring()
        // for index in 0..<population.count {
        //     // let crossover = ga.Crossover(parent1: population[index], parent2: population[(index + 1) % population.count])
        // }
    }
    print("Took \(time) seconds to cook genetic algorithm.")
}


//Run program:
main()
