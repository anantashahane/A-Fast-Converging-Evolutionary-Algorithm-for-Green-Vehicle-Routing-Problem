import Foundation


func main() {
    let clock = ContinuousClock()
    var routines = [Routine]()
    var ga : GeneticAlgorithm? = nil
    let time = clock.measure{
        if let benchmark = ReadFile(filePath: "Benchmarks/A-n32-k5.json") {
            ga = GeneticAlgorithm(benchmark: benchmark, populationCount: 100, iterations: 500)
            if let ga = ga {
                routines = ga.run()
            }
        }
    }
    for routine in routines {
        print(routine)
    }
    print("Took \(time) seconds to cook genetic algorithm.")
}


//Run program:
main()
