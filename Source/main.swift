import Foundation

func PrintHelp() {
    print("Welcome to High Effeciency Selective Optimisaiton-Green Vehicle Routing Problem")
        print("-------------------------------------------------------------------------------\n")
        print("Usage:\n `./heso-vrp [fileName | -] [population] [iterations] [index]`")
        print("Where fileName is the file name prefix from Benchmark directory, so A-n32-k5.json becomes A-n32-k5, if not assigned all benchmarks are run.")
        print("      population is population size generating (λ + μ) = (population + population); defaults to 100.")
        print("      iterations is number of generations for which the genetic algorithm is run; defaults to 500.")
        print("      index is run number; defaults to 1.")
        print("The program expects to get 4 arguements after run command.")
}

func RunExperiment(containingName: String?, index: Int = 1, populationCount: Int = 100, iterations: Int = 500) {
    var results = (history: [Routine](), front: [Routine]())
    for benchmarkPath in GetAllBenchmarks(benchmarkNameContains: containingName) {
        let clock = ContinuousClock()
        if let benchmark = ReadFile(filePath: benchmarkPath) {
            let time = clock.measure {
                let ga = GeneticAlgorithm(benchmark: benchmark, populationCount: populationCount, iterations: iterations)
                results = ga.run()
            }
            let experimentInfo = ExperimentInformation(
                name: "test-1",
                runNumber: index,
                populationSize: populationCount,
                iterationCount: iterations,
                benchmark: benchmark,
                history: results.history,
                front: results.front,
                executionTime: Double(time.components.seconds)
            )
            logExperiment(experimentInfo: experimentInfo)
        }
    }
}

func main() {
    let args = CommandLine.arguments

    if args.contains("--help") {
        PrintHelp()
        return
    }

    // Defaults
    var benchmarkNameContains: String? = nil
    var population = 100
    var iterations = 500
    var index = 1

    // Positional args:
    // ./heso-vrp [fileName] [population] [iterations] [index]

    if args.count > 1 {
        let first = args[1]

        // allow "all benchmarks" if explicitly empty or "-"
        if first != "-" {
            benchmarkNameContains = first
        }
    }

    if args.count > 2, let pop = Int(args[2]) {
        population = pop
    }

    if args.count > 3, let it = Int(args[3]) {
        iterations = it
    }

    if args.count > 4, let i = Int(args[4]) {
        index = i
    }

    print("Running with:")
    print("Benchmark filter:", benchmarkNameContains ?? "ALL")
    print("Population:", population)
    print("Iterations:", iterations)
    print("Index:", index)

    RunExperiment(
        containingName: benchmarkNameContains,
        index: index,
        populationCount: population,
        iterations: iterations
    )
}


//Run program:
main()
