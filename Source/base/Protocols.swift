/// A type that can be represented as a single 2D point.
///
/// Used to provide a geometric abstraction over both atomic points
/// and composite structures (e.g. clusters or vehicles).
///
/// The returned point should represent the type’s spatial meaning:
/// - For a single point: its own coordinates
/// - For a collection: a derived representative (e.g. centroid, center of mass)
protocol PointRepresentable {

    /// Returns a representative 2D point for this type.
    ///
    /// - Returns: A tuple `(x, y)` describing the representative position.
    func representativePoint() -> (x: Double, y: Double)
}


protocol Runnable {
    var experimentName : String {get}
    func run() -> (history: [Routine], front: [Routine])
}