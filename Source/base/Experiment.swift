import Foundation

struct ExperimentInformation : Encodable {
    let name : String
    let runNumber : Int

    let populationSize : Int
    let iterationCount : Int
    let benchmark : Benchmark
    let history : [Routine]
    let front : [Routine]
    
    let executionTime : Double
}

func logExperiment(experimentInfo: ExperimentInformation) {
    
    let fileManager = FileManager()
    let pwd = fileManager.currentDirectoryPath
    let basePath = URL(fileURLWithPath: pwd)
    if let resultsURL = generateFolder(at: basePath, named: "results") {
        if let experimentURL = generateFolder(at: resultsURL, named: experimentInfo.name) {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            do {
                let encodedData = try encoder.encode(experimentInfo)

                let fileURL = experimentURL.appendingPathComponent("\(experimentInfo.benchmark.name)-\(experimentInfo.runNumber).json")
                try encodedData.write(to: fileURL)
                print("Saved to:", fileURL.path)
            } catch {
                print("Failed to write data:", error)
            }
        }
    }

}

func generateFolder(at url: URL, named: String) -> URL? {
    let targetPath = url.appendingPathComponent(named)
    let fileManager = FileManager()
    do {
        try fileManager.createDirectory(
            at: targetPath,
            withIntermediateDirectories: true,
            attributes: nil
        )
        print("Created directory \(targetPath)")
    } catch {
        print("Error creating directory: \(targetPath)")
        return nil
    }
    return targetPath
}