# %%
import os
import glob
import time
import psutil
import platform
import subprocess
import pandas as pd
from datetime import datetime

numberofCores = os.cpu_count()
# Resume Index
BenchmarkIterator = 0

benchmarksFiles = glob.glob("./Benchmarks/*/*.json")
benchmarks = [benchmark := benchmarkFile.split("/")[-1].split(".")[0] for benchmarkFile in benchmarksFiles]
df = pd.DataFrame()
df["Benchmarks"] = benchmarks
customers = [customers := int(benchmark.split("-")[1][1:]) for benchmark in benchmarks]
df["Customers"] = customers
df = df.sort_values(["Customers"], ascending=False)
df = df.reset_index()
df = df.drop(["index"], axis=1)
print(df)



benchmarks = df["Benchmarks"]
print(f"{len(benchmarks)} benchmarks")
def CheckOpenProcesses(named):
    names = []
    for proc in psutil.process_iter(['pid', 'name']):
        try:
        # Get process detail as dictionary
            process_info = proc.info
            if process_info["name"] == named:
                names.append(process_info)

        except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
            pass
    return names


def RunCommand(onBenchmark):
    pwd = os.getcwd()
    command = f"cd {pwd}; time ./run contains {onBenchmark}"
    pid = 0
    if platform.system() == "Darwin":                               #macOS
        process = subprocess.Popen(['osascript', '-e', f'tell app "Terminal" to do script "{command}"'])
        pid = process.pid
    else:                                                           #others presumably linux
        process = subprocess.Popen(['gnome-terminal', '-e', f'tell app "Terminal" to do script "{command}"'])
        pid = process.pid
    return pid


continueFlag = True
while continueFlag:
    processes = CheckOpenProcesses("run")
    if len(processes) < numberofCores:
        if BenchmarkIterator < len(benchmarks):
            pid = RunCommand(benchmarks[BenchmarkIterator])
            currentTime = datetime.now()
            formatted_time = currentTime.strftime("%H:%M")
            print(f"{BenchmarkIterator + 1}/{len(benchmarks)}: {benchmarks[BenchmarkIterator]} started at {formatted_time}")
            BenchmarkIterator += 1
        else:
            currentTime = datetime.now()
            formatted_time = currentTime.strftime("%H:%M")
            print(f"{formatted_time} Done")
            continueFlag = False
    time.sleep(10)

