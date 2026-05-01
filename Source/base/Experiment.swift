import Foundation

//#MARK: - Relational DB Compression.
struct EncodableTruck : Encodable {
    let id = UUID()
    let sequence : [Int]
    let score : [OptimisationObjective : Double]
}

struct EncodableRoutine : Encodable {
    let trucks : [UUID]
    let strictness : Double
    let generation : Int
}

struct CompressedExperimentInformation : Encodable {

    let name : String
    let runNumber : Int

    let populationSize : Int
    let iterationCount : Int
    let benchmark : Benchmark

    let trucks : [EncodableTruck]
    let history : [EncodableRoutine]
    let front : [EncodableRoutine]
    
    let executionTime : Double
}

func CompressRoutines(history: [Routine], front: [Routine]) -> (trucks: [EncodableTruck], history: [EncodableRoutine], front: [EncodableRoutine]) {
    var uniqueTrucks = [String : EncodableTruck]()
    for (_, truck) in history.flatMap({$0.GetTrucks()}) {
        uniqueTrucks[truck.GetID()] = EncodableTruck(sequence: truck.GetSequence(), score: truck.GetAllFitness())
    }
    var encodableHistory = [EncodableRoutine]()
    for routine in history {
        encodableHistory.append(
            EncodableRoutine(
                trucks: routine.GetTrucks().map({
                    uniqueTrucks[$0.element.GetID()]!.id
                }),
                strictness: routine.GetStrictness(),
                generation: routine.generation
            )
        )
    }

    var encodableFront = [EncodableRoutine]()
    for routine in front {
        encodableFront.append(
            EncodableRoutine(
                trucks: routine.GetTrucks().map({
                    uniqueTrucks[$0.element.GetID()]!.id
                }),
                strictness: routine.GetStrictness(),
                generation: routine.generation
            )
        )
    }
    return (trucks: Array(uniqueTrucks.values), history: encodableHistory, front: encodableFront)
}

func CompressExperimentInformation(experimentInfo: ExperimentInformation) -> CompressedExperimentInformation {
    let compressedData = CompressRoutines(history: experimentInfo.history, front: experimentInfo.front)
    return CompressedExperimentInformation(
        name: experimentInfo.name,
        runNumber: experimentInfo.runNumber,

        populationSize: experimentInfo.populationSize,
        iterationCount: experimentInfo.iterationCount,
        benchmark: experimentInfo.benchmark,

        trucks: compressedData.trucks,
        history: compressedData.history,
        front: compressedData.front,

        executionTime: experimentInfo.executionTime
    )
}

struct ExperimentInformation {
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
    let compressedData = CompressExperimentInformation(experimentInfo: experimentInfo)
    if let resultsURL = generateFolder(at: basePath, named: "results") {
        if let experimentURL = generateFolder(at: resultsURL, named: experimentInfo.name) {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            do {
                let encodedData = try encoder.encode(compressedData)

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