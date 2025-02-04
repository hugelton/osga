# src/nami/effects/base.py

import numpy as np
from abc import ABC, abstractmethod
from typing import Optional, Dict, Any
from collections import deque

class AudioEffect(ABC):
    """Base class for audio effects"""
    def __init__(self, sample_rate: int = 44100):
        self.sample_rate = sample_rate
        self.bypass = False
        self.wet = 1.0    # Wet (processed) signal level
        self.dry = 0.0    # Dry (unprocessed) signal level

    def set_mix(self, wet: float, dry: float):
        """Set wet/dry mix levels"""
        self.wet = max(0.0, min(1.0, wet))
        self.dry = max(0.0, min(1.0, dry))

    @abstractmethod
    def process(self, samples: np.ndarray) -> np.ndarray:
        """Process audio samples"""
        pass

    def reset(self):
        """Reset effect state"""
        pass

class DelayLine:
    """Helper class for delay-based effects"""
    def __init__(self, max_delay_ms: float, sample_rate: int = 44100):
        self.sample_rate = sample_rate
        self.max_delay_samples = int(max_delay_ms * sample_rate / 1000)
        self.buffer = deque([0.0] * self.max_delay_samples, maxlen=self.max_delay_samples)
        self.delay_samples = self.max_delay_samples

    def set_delay(self, delay_ms: float):
        """Set delay time in milliseconds"""
        self.delay_samples = min(
            self.max_delay_samples,
            int(delay_ms * self.sample_rate / 1000)
        )

    def process(self, sample: float) -> float:
        """Process a single sample"""
        # Get delayed sample
        out = self.buffer[0]
        
        # Add new sample
        self.buffer.append(sample)
        
        return out

class ParametricEQ:
    """Helper class for parametric equalizer"""
    def __init__(self, sample_rate: int = 44100):
        self.sample_rate = sample_rate
        self.b0 = self.b1 = self.b2 = 0.0
        self.a1 = self.a2 = 0.0
        self.x1 = self.x2 = 0.0
        self.y1 = self.y2 = 0.0

    def set_params(self, freq: float, q: float, gain_db: float):
        """Set EQ parameters"""
        w0 = 2.0 * np.pi * freq / self.sample_rate
        alpha = np.sin(w0) / (2.0 * q)
        A = np.power(10, gain_db / 40.0)

        # Calculate filter coefficients
        self.b0 = 1.0 + alpha * A
        self.b1 = -2.0 * np.cos(w0)
        self.b2 = 1.0 - alpha * A
        self.a0 = 1.0 + alpha / A
        self.a1 = -2.0 * np.cos(w0)
        self.a2 = 1.0 - alpha / A

        # Normalize coefficients
        self.b0 /= self.a0
        self.b1 /= self.a0
        self.b2 /= self.a0
        self.a1 /= self.a0
        self.a2 /= self.a0

    def process(self, sample: float) -> float:
        """Process a single sample"""
        # Process sample
        y = (self.b0 * sample + self.b1 * self.x1 + self.b2 * self.x2 
             - self.a1 * self.y1 - self.a2 * self.y2)

        # Update state
        self.x2 = self.x1
        self.x1 = sample
        self.y2 = self.y1
        self.y1 = y

        return y

class FilterState:
    """Helper class for filter state management"""
    def __init__(self):
        self.x1 = self.x2 = 0.0
        self.y1 = self.y2 = 0.0

    def reset(self):
        """Reset filter state"""
        self.x1 = self.x2 = 0.0
        self.y1 = self.y2 = 0.0
