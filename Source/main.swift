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
        for (index, individual) in ga.GetOffspring().enumerated() {
            print("------------------(\(index + 1))------------------")
            print(individual.description)
            let mutara = ga.LNS(individual: individual, strictness: 7.24)
            print(mutara.description)
        }
    }
    print("Took \(time) seconds to cook genetic algorithm.")
}


//Run program:
main()
