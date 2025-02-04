# src/nami/lua_binding.py

from lupa import LuaRuntime
from typing import Optional, Any
import os.path
from .core.engine import NamiEngine
from .synthesis.oscillator import Oscillator, WaveformType
from .synthesis.envelope import ADSREnvelope
from .effects.processors import Delay, Filter, Reverb


class NamiLuaEngine:
    """Lua binding for NAMI audio system"""

    def __init__(self, nami_instance):
        print("Creating new Lua runtime...")
        self.nami = nami_instance
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.active_sources = {}
        self.active_effects = {}
        self.channels = {}

        # Ensure immediate API setup
        self._setup_api()
        print("Lua runtime created and API setup complete")

    def _create_nami_table(self):
        """Create the nami API table"""
        nami_table = self.lua.table()

        # Add all API functions
        nami_table.init = lambda *args: self.nami.init(*args)
        nami_table.start = lambda: self.nami.start()
        nami_table.stop = lambda: self.nami.stop()
        nami_table.createOscillator = self._create_oscillator
        nami_table.createSynth = self._create_synth
        nami_table.createDelay = self._create_delay
        nami_table.createFilter = self._create_filter
        nami_table.createReverb = self._create_reverb
        nami_table.createChannel = self._create_mixer_channel
        nami_table.setChannelVolume = self._set_channel_volume
        nami_table.setChannelPan = self._set_channel_pan
        nami_table.connectToChannel = self._connect_to_channel

        return nami_table

    def _setup_api(self):
        """Setup NAMI API in Lua"""
        print("Setting up NAMI Lua API...")

        # Create and verify nami table
        nami_table = self._create_nami_table()
        if not nami_table:
            print("Failed to create nami table")
            return False

        # Get the Lua globals
        g = self.lua.globals()

        # Set the global nami table
        try:
            g.nami = nami_table

            # Verify the table was set correctly
            if hasattr(g, "nami"):
                print("nami global table created successfully")
                # Print available functions for debugging
                funcs = [attr for attr in dir(g.nami) if not attr.startswith("_")]
                print(f"Available NAMI functions: {', '.join(funcs)}")
                return True
            else:
                print("Failed to set nami global table")
                return False
        except Exception as e:
            print(f"Error setting up NAMI API: {e}")
            return False

    def _create_oscillator(self):
        """Create a new oscillator instance"""
        osc = Oscillator(self.nami.engine.sample_rate)
        id = len(self.active_sources)
        self.active_sources[id] = osc

        # Create Lua table for the oscillator interface
        osc_interface = self.lua.table()
        osc_interface.id = id
        osc_interface.setWaveform = lambda wf: osc.set_waveform(WaveformType(wf))
        osc_interface.setFrequency = lambda freq: osc.set_frequency(freq)
        osc_interface.setAmplitude = lambda amp: osc.set_amplitude(amp)
        osc_interface.generate_samples = lambda num: osc.generate_samples(num)

        return osc_interface

    def _create_synth(self):
        """Create a new synthesizer with envelope"""
        osc = Oscillator(self.nami.engine.sample_rate)
        env = ADSREnvelope(self.nami.engine.sample_rate)
        id = len(self.active_sources)

        # Create a combined source
        class SynthSource:
            def __init__(self, osc, env):
                self.osc = osc
                self.env = env

            def generate_samples(self, num_samples):
                osc_samples = self.osc.generate_samples(num_samples)
                env_samples = self.env.generate_samples(num_samples)
                return osc_samples * env_samples

        synth = SynthSource(osc, env)
        self.active_sources[id] = synth

        # Create Lua table for the synth interface
        synth_interface = self.lua.table()
        synth_interface.id = id
        synth_interface.setWaveform = lambda wf: osc.set_waveform(WaveformType(wf))
        synth_interface.setFrequency = lambda freq: osc.set_frequency(freq)
        synth_interface.setAmplitude = lambda amp: osc.set_amplitude(amp)
        synth_interface.setAttack = lambda t: env.set_attack(t)
        synth_interface.setDecay = lambda t: env.set_decay(t)
        synth_interface.setSustain = lambda l: env.set_sustain(l)
        synth_interface.setRelease = lambda t: env.set_release(t)
        synth_interface.noteOn = lambda: env.note_on()
        synth_interface.noteOff = lambda: env.note_off()
        synth_interface.generate_samples = lambda num: synth.generate_samples(num)

        return synth_interface

    def _create_mixer_channel(self):
        """Create a new mixer channel"""
        channel_id = self.nami.mixer.add_channel()
        self.channels[channel_id] = channel_id
        return channel_id

    def _set_channel_volume(self, channel_id: int, volume: float):
        """Set channel volume"""
        if channel_id in self.channels:
            self.nami.mixer.set_channel_volume(channel_id, volume)

    def _set_channel_pan(self, channel_id: int, pan: float):
        """Set channel pan position"""
        if channel_id in self.channels:
            self.nami.mixer.set_channel_pan(channel_id, pan)

    def _connect_to_channel(self, source_id: int, channel_id: int):
        """Connect a source to a mixer channel"""
        if source_id in self.active_sources and channel_id in self.channels:
            source = self.active_sources[source_id]
            self.nami.mixer.set_channel_source(channel_id, source)
            return True
        return False

    # ... (rest of the effect creation methods remain the same)

    def loadScript(self, script_path: str) -> bool:
        """Load and execute Lua script"""
        try:
            if not os.path.exists(script_path):
                raise FileNotFoundError(f"Script not found: {script_path}")

            print(f"Loading Lua script: {script_path}")

            # Verify nami global exists before loading script
            g = self.lua.globals()
            if not hasattr(g, "nami"):
                print("Recreating nami table before loading script...")
                self._setup_api()

            with open(script_path, "r") as f:
                script_content = f.read()

            print("Executing script...")
            self.lua.execute(script_content)

            # Verify nami global after script execution
            if hasattr(g, "nami"):
                print("nami global available after script load")
                return True
            else:
                print("Warning: nami global not found after script load")
                return False

        except Exception as e:
            print(f"Error loading script: {e}")
            import traceback

            traceback.print_exc()
            return False
