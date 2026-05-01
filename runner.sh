#!/usr/bin/env bash

set -e

BENCHMARK_DIR="Benchmarks"
EXECUTABLE="./heso_vrp"

# safety checks
if [ ! -f "$EXECUTABLE" ]; then
    echo "Error: $EXECUTABLE not found"
    exit 1
fi

if [ ! -d "$BENCHMARK_DIR" ]; then
    echo "Error: $BENCHMARK_DIR not found"
    exit 1
fi

# list benchmarks (strip .json)
BENCHMARKS=$(ls "$BENCHMARK_DIR" | sed 's/\.json$//')

run_benchmark() {
    local bench=$1

    echo "=== Running benchmark: $bench ==="

    export EXECUTABLE bench

    seq 1 10 | parallel --no-notice \
        "$EXECUTABLE" "$bench" 100 500 {}
}

export -f run_benchmark
export EXECUTABLE

# run benchmarks sequentially
for bench in $BENCHMARKS; do
    run_benchmark "$bench"
done