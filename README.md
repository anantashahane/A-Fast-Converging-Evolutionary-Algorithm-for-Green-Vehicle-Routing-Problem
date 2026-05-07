

# High-Efficiency Selective Optimisation for the Green Vehicle Routing Problem
[![Swift](https://www.swift.org/assets/images/swift~dark.svg)](https://www.swift.org)

A research-oriented experimental framework for studying the combination of the Corridor Model with the Capacitated Vehicle Routing Problem (CVRP).

This project introduces an analogue of the Corridor Model using **dot-product locality estimation** and a **probabilistic roulette operator** to improve inter-generational convergence speed in evolutionary optimisation.

Rather than focusing solely on *which mutation operator* to use, this work explores how to *mutate optimally*. By leveraging customer locality relative to:

* the depot (**static anchoring**), and
* neighbouring customers (**dynamic anchoring**),

the algorithm approximates higher-quality mutations that accelerate convergence toward efficient routing solutions.

Additionally, this project introduces an improved population initialisation strategy capable of producing solutions within approximately **30%–60% of optimal travel distance** at the start of execution. This significantly reduces early-stage search overhead and allows later generations to focus on higher-order optimisation objectives.

The initialiser is designed to:

* Spend more evolutionary iterations optimising secondary objectives.
* Provide strong initial populations for other multi-objective VRP formulations.
* Improve convergence stability across benchmark datasets.

## Research Background

This work is a continuation of a poster published at the ACM GECCO 2024 Companion Conference.
```tex
\copyrightyear{2024}
\acmYear{2024}
\setcopyright{rightsretained}
\acmConference[GECCO '24 Companion]{Genetic and Evolutionary Computation Conference}{July 14--18, 2024}{Melbourne, VIC, Australia}
\acmBooktitle{Genetic and Evolutionary Computation Conference (GECCO '24 Companion), July 14--18, 2024, Melbourne, VIC, Australia}
\acmDOI{10.1145/3638530.3654323}
\acmISBN{979-8-4007-0495-6/24/07}
```

## Running Experiments

Creating a New Experiment

The base `GeneticAlgorithm` class conforms to the `Runnable` protocol.

Each experiment implementation must provide:

* **`experimentName`**
    ```Swift
        var experimentName: String {
            "experiment_name"
        }
    ```
* **`run()`**
    ```Swift
        func run() -> (history: [Routine], front: [Routine]) {
            // Algorithm logic
            return (history: self.history, front: self.fronts[0])
        }
    ```
To add a new experiment:

1. Create a new source file inside `./Source/`
    ```bash
        touch ./Source/foo.swift
    ```
2. Implement an extension on `GeneticAlgorithm` containing the two required members above.
3. The Makefile will automatically detect and register the new experiment.

## Building

Display available experiments by:
```bash
    make help
```
Which generates:
```bash
    Usage:
    make ALG=<option> build

    Available options:
    - foo
    - Noisy-TumbleWeed-DynamicAnchoring
    - ...
    - Noisy-TumbleWeed-StaticAnchoring

    Example:
    make ALG=A build
```
Build a specific experiment:
```bash
    make ALG=foo build
```

## Running
```bash
    ./heso_vrp [BenchmarkName] [populationSize] [iterationCount] [index?]
```
Arguments

| Argument | Description |
|---|---|
| `BenchmarkName` | Benchmark from `./Benchmarks`. Use `-` to run all benchmarks. The executable and `Benchmarks` directory should be in same directory.|
| `populationSize` | Population size for the evolutionary algorithm. |
| `iterationCount` | Number of optimisation iterations. |
| `index?` | Optional output identifier. Defaults to `1`. Useful for repeated runs. |

## Parallel Execution

For statistically meaningful results, it is recommended to generate at least **10 runs per benchmark**.

Experiments can be executed concurrently using GNU Parallel:
```sh
    sh runner.sh
```
Notes

* A (100 + 100) evolutionary configuration with 500 iterations produces approximately **13 GB** of output data.
* Running the full benchmark suite (920 instances) takes roughly **2h 58m** on an Apple M4 chip.
* The current parallel execution implementation will be replaced in the future with native Swift concurrency.

## Result Format

Each experiment generates a directory under:

    ./results/<experimentName>/

For every benchmark run, the program produces a JSON file named:

    <benchmarkName>-<index>.json

The file stores a compressed representation of the experiment state and final Pareto front.

---

## Top-Level Structure

```swift
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
```

---

## Field Description

| Field | Description |
|---|---|
| `name` | Name of the experiment configuration. |
| `runNumber` | Numerical identifier for repeated runs. |
| `populationSize` | Evolutionary population size used during optimisation. |
| `iterationCount` | Number of optimisation iterations executed. |
| `benchmark` | Benchmark instance loaded from `./Benchmarks`. |
| `trucks` | Shared truck pool used by all encoded routines. |
| `history` | Historical population evolution across generations. |
| `front` | Final Pareto front produced by the algorithm. |
| `executionTime` | Total runtime in seconds. |

---

## `EncodableTruck`

Represents a reusable truck route entry.

```swift
struct EncodableTruck : Encodable {
    let id : Int
    let sequence : [Int]
    let score : [String : Double]
}
```

### Fields

| Field | Description |
|---|---|
| `id` | Unique truck identifier used as a foreign key. |
| `sequence` | Ordered list of customer IDs representing the route. |
| `score` | Objective scores associated with the route (e.g. distance, fuel consumption). |

---

## `EncodableRoutine`

Represents a candidate solution within the evolutionary process.

```swift
struct EncodableRoutine : Encodable {
    let trucks : [Int]
    let strictness : Double
    let generation : Int
}
```

### Fields

| Field | Description |
|---|---|
| `trucks` | References to `EncodableTruck.id`. |
| `strictness` | Corridor strictness value used during mutation updates. |
| `generation` | Generation index where the routine was produced. |

---

## Design Notes

The result format is intentionally compressed to minimise disk usage during large-scale experimentation.

A naive serialisation approach that duplicated full route information for every routine produced approximately **121 GB** of output data during benchmark execution.

To reduce storage overhead, the experiment format separates reusable truck routes from evolutionary routines:

- truck routes are stored once in `trucks`,
- routines reference trucks using integer IDs,
    - hence fitness of the routines is the aggregate fitness of the trucks its referenced trucks.
- historical populations reuse shared route entries instead of duplicating them.

This compression scheme reduced the storage footprint to approximately **13 GB** for the same workload configuration.

The reduced output size significantly improves:

- long-running benchmark scalability,
- multi-run statistical experimentation,
- filesystem performance,
- result archival and post-processing efficiency.

This design is especially important because a full benchmark sweep may execute hundreds of instances across many generations and repeated runs.

## Example Output Layout

    ./results/
    └── Experiment_Name/
        ├── A-n32-k5-1.json
        ├── A-n32-k5-2.json
        ├── A-n37-k6-1.json
        └── ...


## Project Goals

* Faster evolutionary convergence for CVRP variants.
* Improved mutation locality heuristics.
* Better initial population quality.
* Scalable experimentation for multi-objective routing problems.
* Reproducible benchmark-driven optimisation research.

<!-- ## Undertanding Outputs
<TODO> explaination.
