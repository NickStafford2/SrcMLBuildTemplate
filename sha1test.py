import hashlib
import time


def run_test(label, data, iterations):
    start = time.perf_counter()
    for _ in range(iterations):
        hashlib.sha1(data).hexdigest()
    end = time.perf_counter()

    total = end - start
    avg = total / iterations

    print(f"{label}")
    print(f"  Data size: {len(data)} bytes")
    print(f"  Iterations: {iterations}")
    print(f"  Total time: {total:.6f} seconds")
    print(f"  Avg per SHA-1: {avg * 1e6:.3f} microseconds")
    print("")


# Prepare test strings
short_str = b"hello world"
long_str = b"A" * 500000  # 500 KB long string for realistic subtree size

tests = [
    ("Short string, 10,000 iterations", short_str, 10_000),
    ("Short string, 100,000 iterations", short_str, 100_000),
    ("Short string, 1,000,000 iterations", short_str, 1_000_000),
    ("Long string, 10,000 iterations", long_str, 10_000),
    ("Long string, 100,000 iterations", long_str, 100_000),
    ("Long string, 1,000,000 iterations", long_str, 1_000_000),
]

for label, data, iters in tests:
    run_test(label, data, iters)
