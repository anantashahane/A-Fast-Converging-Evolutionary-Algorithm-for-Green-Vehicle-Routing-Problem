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
        self.distanceMatrix = GeneticAlgorithm.buildDistanceMatrix(from: benchmark)

        var points: [Point] = []
        var demand: Double = 0.0
        let allCustomers = Array(self.Customers.values)
        while demand <= self.benchmark.capacity, !allCustomers.isEmpty {
            let customer = allCustomers.randomElement()!

            // prevent duplicates
            if points.contains(where: { $0.id == customer.id }) {
                continue
            }
            demand += customer.demand
            if demand < self.benchmark.capacity {
                points.append(customer)
            }
        }
    }
    
    //#MARK:- Helper functions:
    private static func euclideanDistance(from: PointRepresentable, to: PointRepresentable) -> Double {
        let p1 = from.representivePoint()
        let p2 = to.representivePoint()

        return sqrt(pow(p1.x - p2.x, 2) + pow(p1.y - p2.y, 2))
    }

    private static func buildDistanceMatrix(from benchmark: Benchmark) -> [[Double]] {
        var distanceMatrix = Array(repeating: 
                Array(repeating: 0.0, count: benchmark.points.count + 1), count: benchmark.points.count + 1)
        for (idx1, point1) in benchmark.points.enumerated() {
            for (idx2, point2) in benchmark.points.enumerated() where point1.id != point2.id {
                distanceMatrix[idx1 + 1][idx2 + 1] = euclideanDistance(from: point1, to: point2)
            }
        }
        return distanceMatrix
    }


}

func main() {
    if let benchmark = ReadFile(filePath: "../Benchmarks/A-n32-k5.json") {
        let ga = GeneticAlgorithm(benchmark: benchmark, populationCount: 100, iterations: 5000)
    }
}