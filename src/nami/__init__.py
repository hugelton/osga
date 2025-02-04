# src/nami/__init__.py

from .core.engine import NamiEngine
from .synthesis.oscillator import Oscillator, WaveformType
from .synthesis.envelope import ADSREnvelope
from .mixer.mixer import Mixer, AudioChannel
from .effects.processors import Delay, Filter, Reverb
from .lua_binding import NamiLuaEngine


class NAMI:
    """Main NAMI audio system class"""

    def __init__(self):
        print("NAMI: Initializing core components...")
        self.engine = NamiEngine()
        self.mixer = Mixer()
        self.lua_engine = None

    def _init_lua_engine(self):
        """Initialize Lua engine and setup API"""
        try:
            print("NAMI: Initializing Lua engine...")
            self.lua_engine = NamiLuaEngine(self)

            # Verify nami global exists
            g = self.lua_engine.lua.globals()
            if hasattr(g, "nami"):
                print("NAMI: 'nami' global is available")
                # Print available nami functions
                nami_funcs = [attr for attr in dir(g.nami) if not attr.startswith("_")]
                print(f"NAMI: Available nami functions: {', '.join(nami_funcs)}")
            else:
                print("NAMI: Warning - 'nami' global not found")
                return False

            return True
        except Exception as e:
            print(f"NAMI: Failed to initialize Lua engine: {e}")
            return False

    def init(
        self, sample_rate: int = 44100, channels: int = 2, buffer_size: int = 1024
    ) -> bool:
        """Initialize NAMI audio system"""
        try:
            print(
                f"NAMI: Initializing audio system (sr={sample_rate}, ch={channels}, bs={buffer_size})..."
            )

            if not self.engine.init(sample_rate, channels, buffer_size):
                print("NAMI: Failed to initialize audio engine")
                return False

            # Initialize Lua engine if not already done
            if self.lua_engine is None:
                print("NAMI: No Lua engine found, initializing...")
                if not self._init_lua_engine():
                    print("NAMI: Failed to initialize Lua engine")
                    return False

            # Ensure nami global exists
            g = self.lua_engine.lua.globals()
            if not hasattr(g, "nami"):
                print("NAMI: Recreating nami global...")
                self.lua_engine._setup_api()
                if not hasattr(g, "nami"):
                    print("NAMI: Failed to create nami global")
                    return False

            print("NAMI: Initialization completed successfully")
            return True

        except Exception as e:
            print(f"NAMI: Error in initialization: {e}")
            import traceback

            traceback.print_exc()
            return False

    def start(self) -> bool:
        """Start audio processing"""
        print("NAMI: Starting audio processing...")
        return self.engine.start()

    def stop(self):
        """Stop audio processing"""
        print("NAMI: Stopping audio processing...")
        self.engine.stop()

    def create_oscillator(self) -> Oscillator:
        """Create a new oscillator"""
        return Oscillator(self.engine.sample_rate)

    def create_envelope(self) -> ADSREnvelope:
        """Create a new ADSR envelope"""
        return ADSREnvelope(self.engine.sample_rate)

    def create_delay(self) -> Delay:
        """Create a new delay effect"""
        return Delay(self.engine.sample_rate)

    def create_filter(self) -> Filter:
        """Create a new filter effect"""
        return Filter(self.engine.sample_rate)

    def create_reverb(self) -> Reverb:
        """Create a new reverb effect"""
        return Reverb(self.engine.sample_rate)

    def add_mixer_channel(self) -> int:
        """Add a new mixer channel"""
        return self.mixer.add_channel()

    def load_lua_script(self, script_path: str) -> bool:
        """Load and execute Lua script"""
        if self.lua_engine is None:
            print("NAMI: Error - Lua engine not initialized")
            return False

        print(f"NAMI: Loading Lua script: {script_path}")

        # Verify nami global exists before loading script
        g = self.lua_engine.lua.globals()
        if not hasattr(g, "nami"):
            print("NAMI: Recreating nami global before script load...")
            self.lua_engine._setup_api()

        # Print available globals before script load
        print("NAMI: Available globals before script load:", ", ".join(dir(g)))

        result = self.lua_engine.loadScript(script_path)

        # Print available globals after script load
        print("NAMI: Available globals after script load:", ", ".join(dir(g)))

        if not result:
            print("NAMI: Failed to load script")
        return result

    def __del__(self):
        """Cleanup"""
        self.stop()
