# scripts/run_nami_test.py

import time
import sys
from src.nami import NAMI
from collections import deque


class AudioTester:
    def __init__(self):
        print("Creating NAMI instance...")
        self.nami = NAMI()
        self.performance_times = deque(maxlen=30)
        self.last_time = time.time()

    def init(self):
        """Initialize NAMI system"""
        print("Initializing NAMI audio system...")

        # Initialize with standard audio settings
        if not self.nami.init(sample_rate=44100, channels=2, buffer_size=1024):
            print("Failed to initialize NAMI")
            return False

        # Verify Lua initialization
        if self.nami.lua_engine is None:
            print("Failed to initialize Lua engine")
            return False

        # Check Lua globals
        g = self.nami.lua_engine.lua.globals()
        print(f"Available Lua globals: {', '.join(dir(g))}")
        if hasattr(g, "nami"):
            print("nami global is available")
            # Print available nami functions
            nami_funcs = [attr for attr in dir(g.nami) if not attr.startswith("_")]
            print(f"Available nami functions: {', '.join(nami_funcs)}")
        else:
            print("Error: nami global not found")
            return False

        print("NAMI initialization completed successfully")
        return True

    def run(self):
        """Run the test script"""
        try:
            print("\nLoading test script...")
            script_path = "scripts/tests/nami_test.lua"

            if not self.nami.load_lua_script(script_path):
                print(f"Failed to load test script: {script_path}")
                return

            # Verify Lua state after script load
            g = self.nami.lua_engine.lua.globals()
            print(
                f"Lua functions after script load: {', '.join(name for name in dir(g) if callable(getattr(g, name)))}"
            )

            print("\nStarting audio playback...")
            if not self.nami.start():
                print("Failed to start audio playback")
                return

            # Call Lua initialization
            if "init" in g:
                try:
                    print("Calling Lua init()...")
                    g.init()
                except Exception as e:
                    print(f"Error in Lua init(): {e}")
                    import traceback

                    traceback.print_exc()
                    return
            else:
                print("Warning: init() function not found in Lua script")

            print("\nEntering main loop...")
            try:
                while True:
                    current_time = time.time()
                    delta = current_time - self.last_time
                    self.performance_times.append(delta)
                    self.last_time = current_time

                    if "update" in g:
                        g.update()

                    if len(self.performance_times) >= 30:
                        avg_time = sum(self.performance_times) / len(
                            self.performance_times
                        )
                        fps = 1.0 / avg_time if avg_time > 0 else 0
                        metrics = self.nami.engine.get_metrics()

                        print(
                            f"\rFPS: {fps:.1f} | CPU: {metrics['cpu_load']:.1f}% | "
                            f"Latency: {metrics['latency_ms']:.1f}ms | "
                            f"Peak: {metrics['peak_level']:.2f}",
                            end="",
                        )

                    time.sleep(max(0, 1.0 / 60.0 - delta))

            except KeyboardInterrupt:
                print("\nTest terminated by user")

        except Exception as e:
            print(f"\nTest error: {e}")
            import traceback

            traceback.print_exc()

        finally:
            self.cleanup()

    def cleanup(self):
        """Clean up resources"""
        print("\nCleaning up...")
        if self.nami.lua_engine:
            g = self.nami.lua_engine.lua.globals()
            if "cleanup" in g:
                try:
                    g.cleanup()
                except Exception as e:
                    print(f"Error in Lua cleanup(): {e}")
        self.nami.stop()


def main():
    tester = AudioTester()
    if tester.init():
        tester.run()


if __name__ == "__main__":
    main()

