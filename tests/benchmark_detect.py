import time
import base64
import json
import psutil
import platform
import numpy as np
from fastapi.testclient import TestClient
from ai_server import app

client = TestClient(app)

def run_benchmark(num_frames=100):
    with open("tests/data/scene_with_person.png", "rb") as f:
        img_b64 = base64.b64encode(f.read()).decode("utf-8")

    payload = {"image": img_b64}
    
    # Warmup
    print("Warming up with 5 frames...")
    for _ in range(5):
        client.post("/detect", json=payload)

    latencies = []
    process = psutil.Process()
    cpu_percent_start = psutil.cpu_percent(interval=None)
    mem_start = process.memory_info().rss / (1024 * 1024)

    print(f"Running benchmark over {num_frames} frames on /detect...")
    start_total = time.time()
    for i in range(num_frames):
        t0 = time.perf_counter()
        resp = client.post("/detect", json=payload)
        t1 = time.perf_counter()
        assert resp.status_code == 200, f"Frame {i} failed: {resp.text}"
        latencies.append((t1 - t0) * 1000) # in ms

    total_time = time.time() - start_total
    cpu_percent_end = psutil.cpu_percent(interval=0.1)
    mem_end = process.memory_info().rss / (1024 * 1024)

    avg_latency = np.mean(latencies)
    median_latency = np.median(latencies)
    p95_latency = np.percentile(latencies, 95)
    min_latency = np.min(latencies)
    max_latency = np.max(latencies)
    avg_fps = num_frames / total_time

    # System device info
    sys_info = {
        "os": platform.platform(),
        "processor": platform.processor(),
        "machine": platform.machine(),
        "cpu_count": psutil.cpu_count(logical=True),
        "physical_cores": psutil.cpu_count(logical=False),
        "total_ram_gb": round(psutil.virtual_memory().total / (1024**3), 2)
    }

    results = {
        "device": sys_info,
        "num_frames": int(num_frames),
        "total_time_s": float(round(total_time, 2)),
        "avg_fps": float(round(avg_fps, 2)),
        "avg_latency_ms": float(round(avg_latency, 2)),
        "median_latency_ms": float(round(median_latency, 2)),
        "p95_latency_ms": float(round(p95_latency, 2)),
        "min_latency_ms": float(round(min_latency, 2)),
        "max_latency_ms": float(round(max_latency, 2)),
        "cpu_usage_pct": float(round(cpu_percent_end, 1)),
        "ram_start_mb": float(round(mem_start, 1)),
        "ram_end_mb": float(round(mem_end, 1)),
        "ram_diff_mb": float(round(mem_end - mem_start, 1)),
        "target_met_10fps": bool(avg_fps >= 10.0),
        "target_met_200ms": bool(p95_latency <= 200.0)
    }

    print("\n=== BENCHMARK RESULTS ===")
    print(json.dumps(results, indent=2))
    
    with open("tests/benchmark_results.json", "w") as f:
        json.dump(results, f, indent=2)

    return results

if __name__ == "__main__":
    run_benchmark(100)
