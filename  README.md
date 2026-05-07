

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

Meaning each experiment implementation must provide:

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

Display available experiments:
```bash
    make help
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
| `BenchmarkName` | Benchmark from `./Benchmarks`. Use `-` to run all benchmarks. Run binary and `Benchmarks` directory should be in same directory.|
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

* A (100 + 100) evolutionary configuration with 500 iterations produces approximately 13 GB of output data.
* Running the full benchmark suite (920 instances) takes roughly 2h 58m on an Apple M4 chip.
* The current parallel execution implementation may be replaced in the future with native Swift concurrency support.


## Project Goals

* Faster evolutionary convergence for CVRP variants.
* Improved mutation locality heuristics.
* Better initial population quality.
* Scalable experimentation for multi-objective routing problems.
* Reproducible benchmark-driven optimisation research.

<!-- ## Undertanding Outputs
<TODO> explaination.
--- -->