import Foundation


func main() {
    let clock = ContinuousClock()
    var ga : GeneticAlgorithm? = nil
    let time = clock.measure{
        if let benchmark = ReadFile(filePath: "Benchmarks/M-n200-k16.json") {
            ga = GeneticAlgorithm(benchmark: benchmark, populationCount: 100, iterations: 5000)
        }
    }
    // if let ga = ga {
    //     for (index, individual) in ga.InitialisePopulation().enumerated() {
    //         print("------------------(\(index + 1))------------------")
    //         print(individual.description)
    //     }
    // }
    print("Took \(time) seconds to cook genetic algorithm.")
}


//Run program:
main()
