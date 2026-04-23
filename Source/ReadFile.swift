import Foundation

/// A single coordinate point in a benchmark dataset.
///
/// Each point represents a node with an identifier, spatial coordinates,
/// and an associated demand value used in routing / optimization problems.
struct Point: Decodable {
    /// Unique identifier for the point.
    let id: Int
    /// X-coordinate in 2D space.
    let x: Double
    /// Y-coordinate in 2D space.
    let y: Double
    /// Demand value associated with this point.
    let demand: Double
}

/// A benchmark dataset used for vehicle routing / optimization problems.
///
/// This structure describes a full problem instance including metadata
/// (name, capacity constraints, optimality reference) and a list of points
/// that define the spatial problem space.
struct Benchmark: Decodable {
    /// Name identifier of the benchmark dataset.
    let name: String
    /// Category of the benchmark.
    let title: String
    /// Number of available vehicles (trucks).
    let trucks: Int
    /// Maximum capacity of each vehicle.
    let capacity: Double
    /// Known or reference optimality value for this benchmark.
    let optimality: Double
    /// Collection of all points (nodes) in the problem instance.
    let points: [Point]

}

/// Reads and decodes a `Benchmark` JSON file from disk.
///
/// This function loads raw file data from the given path, attempts to decode it
/// into a `Benchmark` structure using `JSONDecoder`, and returns the decoded
/// result if successful.
///
/// - Parameter filePath: Absolute or relative path to the JSON file.
/// - Returns: A decoded `Benchmark` object if parsing succeeds, otherwise `nil`.
///
/// ## Example
/// ```swift
/// if let benchmark = ReadFile(filePath: "data/sample.json") {
///     print(benchmark.name)
/// }
/// ```
/// * json file must comform to `Benchmark` struct.
func ReadFile(filePath: String) -> Benchmark? {
    var benchmark : Benchmark? = nil
    let clock = ContinuousClock()
    let time = clock.measure {
        if let fileData = FileManager().contents(atPath: filePath) {
            let decoder = JSONDecoder()
            if let content = try? decoder.decode(Benchmark.self, from: fileData) {
                benchmark = content
            }
        }   
    }
    if let benchmark = benchmark {
        print("Decode Successful for \(benchmark.name) in \(time)....")

    }
    return benchmark
}

/// Returns all benchmark file paths in the `Benchmarks` directory.
///
/// This function scans the `Benchmarks` folder located at the project root
/// and returns full file paths for all JSON benchmark files. If a filter
/// string is provided, only filenames containing that string are included.
///
/// The function also attempts to handle cases where it is executed from
/// inside the `Source/` directory by adjusting the working directory.
///
/// - Parameter benchmarkNameContains: Optional substring used to filter benchmark filenames.
///   If `nil`, all benchmarks are returned.
///
/// - Returns: A sorted array of full file paths to benchmark JSON files.
///
/// ## Example
/// ```swift
/// let all = GetAllBenchmarks(benchmarkNameContains: nil)
/// let aBenchmarks = GetAllBenchmarks(benchmarkNameContains: "A")
/// ```
func GetAllBenchmarks(benchmarkNameContains: String?) -> [String] {
    var benchmarkPaths = Array<String>()
    let fileManager = FileManager()
    var currentPath = fileManager.currentDirectoryPath
    if currentPath.split(separator: "/").last ?? "Unknown"  == "Source" {
        currentPath = String(currentPath.dropLast("Source".count))
    } else {
        currentPath += "/"
    }
    currentPath += "Benchmarks"
    if let benchmarks = try? fileManager.contentsOfDirectory(atPath: currentPath) {
        if let expectedContent = benchmarkNameContains {
            benchmarkPaths = benchmarks.filter({ $0.contains(expectedContent)}).map({currentPath.appending("/\($0)")})
        } else {
            benchmarkPaths = benchmarks.map({currentPath.appending("/\($0)")})
        }
    }
    return benchmarkPaths.sorted()
}

for benchmark in GetAllBenchmarks(benchmarkNameContains: nil) {
    let _ = ReadFile(filePath: benchmark)
}