import time

def test_sleep_benchmark(benchmark):
    result = benchmark(time.sleep, 0.01)
    assert result is None