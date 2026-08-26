import time
import subprocess

print("Triggering siren...")
start = time.time()
p = subprocess.Popen(["afplay", "siren.wav"])
print(f"Subprocess spawned in {time.time() - start:.3f} seconds")
p.wait()
print(f"Finished in {time.time() - start:.3f} seconds")
