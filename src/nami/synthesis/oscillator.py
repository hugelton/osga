# src/nami/synthesis/oscillator.py

import numpy as np
from enum import Enum
from typing import Optional

class WaveformType(Enum):
    """Available waveform types"""
    SINE = "sine"
    SQUARE = "square"
    TRIANGLE = "triangle"
    SAWTOOTH = "sawtooth"
    NOISE = "noise"

class Oscillator:
    """Base oscillator class for waveform generation"""
    def __init__(self, sample_rate: int = 44100):
        self.sample_rate = sample_rate
        self.frequency = 440.0  # Default frequency (A4)
        self.phase = 0.0        # Current phase
        self.amplitude = 1.0    # Amplitude (0.0 to 1.0)
        self.waveform = WaveformType.SINE
        
        # Phase increment per sample
        self.phase_increment = 2.0 * np.pi * self.frequency / self.sample_rate
        
        # Lookup tables for optimized waveform generation
        self._init_lookup_tables()
    
    def _init_lookup_tables(self):
        """Initialize lookup tables for various waveforms"""
        table_size = 4096
        # Sine table
        self.sine_table = np.sin(np.linspace(0, 2*np.pi, table_size))
        
        # Triangle table
        self.triangle_table = np.abs((np.linspace(0, 4, table_size) % 4) - 2) - 1
        
        # Sawtooth table
        self.saw_table = (np.linspace(0, 2, table_size) % 2) - 1
        
        # Square table (with slight smoothing)
        square = np.ones(table_size)
        square[table_size//2:] = -1
        self.square_table = square
        
        self.table_size = table_size
    
    def set_frequency(self, freq: float):
        """Set oscillator frequency"""
        self.frequency = max(20.0, min(20000.0, freq))  # Clamp to audible range
        self.phase_increment = 2.0 * np.pi * self.frequency / self.sample_rate
    
    def set_amplitude(self, amp: float):
        """Set oscillator amplitude"""
        self.amplitude = max(0.0, min(1.0, amp))
    
    def set_waveform(self, waveform: WaveformType):
        """Set waveform type"""
        if isinstance(waveform, str):
            waveform = WaveformType(waveform)
        self.waveform = waveform
    
    def _get_table_value(self, table: np.ndarray) -> float:
        """Get interpolated value from lookup table"""
        index = (self.phase / (2.0 * np.pi)) * self.table_size
        index_int = int(index)
        frac = index - index_int
        
        # Linear interpolation
        next_index = (index_int + 1) % self.table_size
        return table[index_int] * (1.0 - frac) + table[next_index] * frac
    
    def generate_samples(self, num_samples: int) -> np.ndarray:
        """Generate audio samples"""
        samples = np.zeros(num_samples)
        
        for i in range(num_samples):
            if self.waveform == WaveformType.SINE:
                samples[i] = self._get_table_value(self.sine_table)
            elif self.waveform == WaveformType.SQUARE:
                samples[i] = self._get_table_value(self.square_table)
            elif self.waveform == WaveformType.TRIANGLE:
                samples[i] = self._get_table_value(self.triangle_table)
            elif self.waveform == WaveformType.SAWTOOTH:
                samples[i] = self._get_table_value(self.saw_table)
            elif self.waveform == WaveformType.NOISE:
                samples[i] = np.random.uniform(-1, 1)
            
            # Update phase
            self.phase += self.phase_increment
            if self.phase >= 2.0 * np.pi:
                self.phase -= 2.0 * np.pi
        
        return samples * self.amplitude

class PolyOscillator:
    """Polyphonic oscillator for multiple simultaneous notes"""
    def __init__(self, num_voices: int = 8, sample_rate: int = 44100):
        self.num_voices = num_voices
        self.sample_rate = sample_rate
        self.voices = [Oscillator(sample_rate) for _ in range(num_voices)]
        self.active_voices = {}  # note -> voice mapping
        
    def note_on(self, note: int, velocity: float = 1.0):
        """Start playing a note"""
        # Find free voice or steal the oldest one
        voice = None
        for v in self.voices:
            if v not in self.active_voices.values():
                voice = v
                break
        
        if voice is None:
            # No free voices, steal the first one
            voice = self.voices[0]
            
        # Convert MIDI note to frequency
        freq = 440.0 * (2.0 ** ((note - 69) / 12.0))
        voice.set_frequency(freq)
        voice.set_amplitude(velocity)
        self.active_voices[note] = voice
        
    def note_off(self, note: int):
        """Stop playing a note"""
        if note in self.active_voices:
            del self.active_voices[note]
            
    def generate_samples(self, num_samples: int) -> np.ndarray:
        """Generate mixed samples from all active voices"""
        if not self.active_voices:
            return np.zeros(num_samples)
            
        # Mix all active voices
        samples = np.zeros(num_samples)
        for voice in self.active_voices.values():
            samples += voice.generate_samples(num_samples)
            
        # Normalize to prevent clipping
        if len(self.active_voices) > 1:
            samples /= len(self.active_voices)
            
        return samples
