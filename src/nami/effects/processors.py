# src/nami/effects/processors.py

import numpy as np
from typing import List, Optional
from .base import AudioEffect, DelayLine, ParametricEQ, FilterState

class Delay(AudioEffect):
    """Simple delay effect with feedback"""
    def __init__(self, sample_rate: int = 44100):
        super().__init__(sample_rate)
        self.delay_line = DelayLine(1000.0, sample_rate)  # Max 1000ms delay
        self.feedback = 0.3
        self.wet = 0.5
        self.dry = 1.0

    def set_delay_time(self, delay_ms: float):
        """Set delay time in milliseconds"""
        self.delay_line.set_delay(delay_ms)

    def set_feedback(self, feedback: float):
        """Set feedback amount (0.0 to 1.0)"""
        self.feedback = max(0.0, min(0.95, feedback))

    def process(self, samples: np.ndarray) -> np.ndarray:
        if self.bypass:
            return samples

        output = np.zeros_like(samples)
        for i in range(len(samples)):
            delayed = self.delay_line.process(samples[i])
            output[i] = self.dry * samples[i] + self.wet * delayed
            # Add feedback
            self.delay_line.buffer.append(samples[i] + self.feedback * delayed)

        return output

class Filter(AudioEffect):
    """Multi-mode filter (lowpass, highpass, bandpass)"""
    def __init__(self, sample_rate: int = 44100):
        super().__init__(sample_rate)
        self.cutoff = 1000.0
        self.resonance = 0.707
        self.mode = "lowpass"
        self.state = FilterState()
        self._update_coefficients()

    def set_cutoff(self, freq: float):
        """Set filter cutoff frequency"""
        self.cutoff = max(20.0, min(20000.0, freq))
        self._update_coefficients()

    def set_resonance(self, q: float):
        """Set filter resonance"""
        self.resonance = max(0.1, min(10.0, q))
        self._update_coefficients()

    def set_mode(self, mode: str):
        """Set filter mode (lowpass, highpass, bandpass)"""
        if mode in ["lowpass", "highpass", "bandpass"]:
            self.mode = mode
            self._update_coefficients()

    def _update_coefficients(self):
        """Calculate filter coefficients"""
        w0 = 2.0 * np.pi * self.cutoff / self.sample_rate
        alpha = np.sin(w0) / (2.0 * self.resonance)
        cos_w0 = np.cos(w0)

        if self.mode == "lowpass":
            b0 = (1.0 - cos_w0) / 2.0
            b1 = 1.0 - cos_w0
            b2 = (1.0 - cos_w0) / 2.0
            a0 = 1.0 + alpha
            a1 = -2.0 * cos_w0
            a2 = 1.0 - alpha
        elif self.mode == "highpass":
            b0 = (1.0 + cos_w0) / 2.0
            b1 = -(1.0 + cos_w0)
            b2 = (1.0 + cos_w0) / 2.0
            a0 = 1.0 + alpha
            a1 = -2.0 * cos_w0
            a2 = 1.0 - alpha
        else:  # bandpass
            b0 = alpha
            b1 = 0.0
            b2 = -alpha
            a0 = 1.0 + alpha
            a1 = -2.0 * cos_w0
            a2 = 1.0 - alpha

        # Normalize coefficients
        self.b0 = b0 / a0
        self.b1 = b1 / a0
        self.b2 = b2 / a0
        self.a1 = a1 / a0
        self.a2 = a2 / a0

    def process(self, samples: np.ndarray) -> np.ndarray:
        if self.bypass:
            return samples

        output = np.zeros_like(samples)
        for i in range(len(samples)):
            # Process sample through filter
            y = (self.b0 * samples[i] + self.b1 * self.state.x1 + self.b2 * self.state.x2
                 - self.a1 * self.state.y1 - self.a2 * self.state.y2)

            # Update state
            self.state.x2 = self.state.x1
            self.state.x1 = samples[i]
            self.state.y2 = self.state.y1
            self.state.y1 = y

            # Mix dry/wet
            output[i] = self.dry * samples[i] + self.wet * y

        return output

class Reverb(AudioEffect):
    """Simple reverb effect using multiple delay lines"""
    def __init__(self, sample_rate: int = 44100):
        super().__init__(sample_rate)
        # Create multiple delay lines for early reflections
        self.delays = [
            DelayLine(50.0, sample_rate),   # Short early reflection
            DelayLine(100.0, sample_rate),  # Medium early reflection
            DelayLine(150.0, sample_rate),  # Long early reflection
        ]
        # Feedback delay for tail
        self.tail = DelayLine(200.0, sample_rate)
        self.decay = 0.5
        self.room_size = 0.5
        self._update_delays()

    def set_room_size(self, size: float):
        """Set room size (0.0 to 1.0)"""
        self.room_size = max(0.0, min(1.0, size))
        self._update_delays()

    def set_decay(self, decay: float):
        """Set decay time (0.0 to 1.0)"""
        self.decay = max(0.0, min(0.95, decay))

    def _update_delays(self):
        """Update delay times based on room size"""
        base_times = [30.0, 45.0, 60.0]  # Base delay times in ms
        scale = 1.0 + self.room_size * 2.0  # Scale factor based on room size
        
        for delay, base_time in zip(self.delays, base_times):
            delay.set_delay(base_time * scale)
        
        self.tail.set_delay(100.0 * scale)

    def process(self, samples: np.ndarray) -> np.ndarray:
        if self.bypass:
            return samples

        output = np.zeros_like(samples)
        for i in range(len(samples)):
            # Process early reflections
            early_sum = 0.0
            for delay in self.delays:
                early_sum += delay.process(samples[i]) * 0.3

            # Process reverb tail
            tail = self.tail.process(samples[i])
            
            # Mix everything together
            output[i] = (self.dry * samples[i] + 
                        self.wet * (early_sum + self.decay * tail))
            
            # Feed back into tail
            self.tail.buffer.append(samples[i] + self.decay * tail)

        return output
