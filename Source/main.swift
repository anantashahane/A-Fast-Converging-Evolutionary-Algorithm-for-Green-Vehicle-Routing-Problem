import Foundation

for benchmarkPaths in GetAllBenchmarks(benchmarkNameContains: "A-n32-k5") {
    if let benchmark = ReadFile(filePath: benchmarkPaths) {
        let ga = GeneticAlgorithm(benchmark: benchmark, populationCount: 100, iterations: 5000)
    }
}

