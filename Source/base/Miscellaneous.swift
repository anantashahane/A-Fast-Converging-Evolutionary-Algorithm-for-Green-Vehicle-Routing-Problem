import Foundation

func EuclideanDistance(from: PointRepresentable, to: PointRepresentable) -> Double {
    let p1 = from.representativePoint()
    let p2 = to.representativePoint()
    let dx = p1.x - p2.x
    let dy = p1.y - p2.y
    return sqrt((dx * dx) + (dy * dy))
}

func BuildDistanceMatrix(from benchmark: Benchmark) -> [[Double]] {
    var distanceMatrix = Array(repeating: 
            Array(repeating: 0.0, count: benchmark.points.count + 1), count: benchmark.points.count + 1)
    for (idx1, point1) in benchmark.points.enumerated() {
        for (idx2, point2) in benchmark.points.enumerated() where point1.id != point2.id {
            distanceMatrix[idx1 + 1][idx2 + 1] = EuclideanDistance(from: point1, to: point2)
        }
    }
    return distanceMatrix
}

/// Computes a normalized directional dot product between two points
/// relative to an anchor, with an additional penalty based on distance.
///
/// This function measures the angular similarity between the vectors:
/// - `anchor → source`
/// - `anchor → target`
///
/// The result is a shadow of `source`on `target`, with respect to `anchor`, 
/// and the result is penalized by distance between `source` and `target`.
///
/// If any of the involved distances are zero, the function returns `0`
/// to avoid division by zero and degenerate geometry.
///
/// - Parameters:
///   - source: The starting point of the first vector.
///   - target: The endpoint of the second vector.
///   - anchor: The reference origin point for both vectors.
///
/// - Returns: A Double representing the normalized dot product
///   penalized by the distance between `source` and `target`.
///
/// - Important:
///   This function assumes `representativePoint()` returns valid Cartesian coordinates.
///   It will return `0` if any geometric degeneracy is detected.
func DotProduct(source: PointRepresentable, target: PointRepresentable, anchor: PointRepresentable) -> Double {
    let dist = EuclideanDistance(from: source, to: target)
    if (dist == 0 || EuclideanDistance(from: anchor, to: target) == 0 || EuclideanDistance(from: anchor, to: source) == 0) { return 0 }
    
    let p1 = source.representativePoint()
    let p2 = target.representativePoint()
    let a = anchor.representativePoint()

    let v1 = (x: p1.x - a.x, y: p1.y - a.y)
    let v2 = (x: p2.x - a.x, y: p2.y - a.y)
    
    let targetLength = sqrt((v2.x * v2.x) + (v2.y * v2.y))
    return ((v1.x * v2.x) + (v1.y * v2.y)) / (dist * targetLength)
}

func GenerateRouletteWheel(strictness: Double, length: Int) -> [Double] {
    // Support function for following functions.
        // Generates a roulettewheel of given size and strictness.
    if length < 1 {
        return []
    }
    var probabilityDistribution = [Double]()
    let selectionPressure = 1 / Double(length)
    var px : Double = 0
    for x in 1...length {
        px += pow((1 - selectionPressure), strictness * Double(x - 1)) * selectionPressure
        probabilityDistribution.append(px)
    }
    probabilityDistribution = probabilityDistribution.map({$0 / px})
    return probabilityDistribution
}

func SpinRouletteWheel<T>(strictness: Double, onCandidates: [T]) -> T? {
    //Accept an array of contents, and spins the roulette wheel on it, returns the values with decreasing probability with increase in index.
        //First elements are more likely to be returned.
    if onCandidates.count == 0 {
        return nil
    }
    let rouletteWheel = GenerateRouletteWheel(strictness: strictness, length: onCandidates.count)
    let randomNumber = Double.random(in: 0...1)
    var returnIndex = 0
    for (index, value) in rouletteWheel.enumerated() {
        if value > randomNumber {
            returnIndex = index
            break
        }
    }
    return onCandidates[returnIndex]
}

extension Double {
    enum RNGError : Error {
        case invalidUpperBound
        case centerOutOfRange
    }
    static func NormalRandom(mu: Double, sigma: Double) -> Double {
        let u1 = Double.random(in: 0...1)
        let u2 = Double.random(in: 0...1)
        
        let z0 = sqrt(-2 * log(u1)) * cos(2 * .pi * u2)
        let randomNumber = z0 * sigma + mu
        
        return randomNumber
    }

    static func RandomNumber(center : Double, upperBound : Double, seed : Double? = nil) throws -> Double {
        var mutableCenter = center
        if upperBound < 0 {
            // print("RNG Error: Upperbound (\(upperBound)) set lower than 0.")
            throw RNGError.invalidUpperBound
        }
        if center >= upperBound || center <= 0 {
            // print("RNG Error: Center (\(center)) out of range [0, \(upperBound)).")
            mutableCenter = upperBound / 2
        }
        var val = 0.0
        if let seed = seed {
            val = seed
        } else {
            val = Double.random(in: 0...1)
        }
        let frontRatio = mutableCenter / upperBound
        if val < frontRatio {
            val = val / frontRatio - 1
            let unscaled = asin(val) + (Double.pi / 2)
            return 2 * unscaled * mutableCenter / Double.pi
        } else {
            val = (val - frontRatio) / (1 - frontRatio)
            let unscaled = asin(val)
            return mutableCenter + (2 * unscaled * (upperBound - mutableCenter)) / Double.pi
        }
    }
}