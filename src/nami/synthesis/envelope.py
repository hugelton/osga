# src/nami/synthesis/envelope.py

from enum import Enum
import numpy as np
from typing import Optional

class EnvelopeState(Enum):
    """ADSR envelope states"""
    IDLE = 0
    ATTACK = 1
    DECAY = 2
    SUSTAIN = 3
    RELEASE = 4

class ADSREnvelope:
    """ADSR (Attack, Decay, Sustain, Release) envelope generator"""
    def __init__(self, sample_rate: int = 44100):
        self.sample_rate = sample_rate
        
        # Default ADSR parameters (in seconds)
        self.attack_time = 0.1
        self.decay_time = 0.2
        self.sustain_level = 0.7
        self.release_time = 0.3
        
        # State management
        self.state = EnvelopeState.IDLE
        self.current_level = 0.0
        self.release_start_level = 0.0
        
        # Time tracking
        self.current_time = 0.0
        self.state_start_time = 0.0
        
        # Calculate rate coefficients
        self._update_coefficients()
    
    def _update_coefficients(self):
        """Update rate coefficients based on current parameters"""
        # Convert times to rates (change per sample)
        self.attack_rate = 1.0 / (self.attack_time * self.sample_rate) if self.attack_time > 0 else 1.0
        self.decay_rate = (1.0 - self.sustain_level) / (self.decay_time * self.sample_rate) if self.decay_time > 0 else 1.0
        self.release_rate = 1.0 / (self.release_time * self.sample_rate) if self.release_time > 0 else 1.0
    
    def set_attack(self, time: float):
        """Set attack time in seconds"""
        self.attack_time = max(0.001, min(5.0, time))
        self._update_coefficients()
    
    def set_decay(self, time: float):
        """Set decay time in seconds"""
        self.decay_time = max(0.001, min(5.0, time))
        self._update_coefficients()
    
    def set_sustain(self, level: float):
        """Set sustain level (0.0 to 1.0)"""
        self.sustain_level = max(0.0, min(1.0, level))
        self._update_coefficients()
    
    def set_release(self, time: float):
        """Set release time in seconds"""
        self.release_time = max(0.001, min(5.0, time))
        self._update_coefficients()
    
    def note_on(self):
        """Trigger note-on event"""
        self.state = EnvelopeState.ATTACK
        self.state_start_time = self.current_time
        if self.current_level == 0.0:
            self.current_level = 0.0001  # Avoid pop at start
    
    def note_off(self):
        """Trigger note-off event"""
        self.state = EnvelopeState.RELEASE
        self.state_start_time = self.current_time
        self.release_start_level = self.current_level
    
    def generate_samples(self, num_samples: int) -> np.ndarray:
        """Generate envelope samples"""
        samples = np.zeros(num_samples)
        
        for i in range(num_samples):
            if self.state == EnvelopeState.ATTACK:
                # Attack phase
                self.current_level += self.attack_rate
                if self.current_level >= 1.0:
                    self.current_level = 1.0
                    self.state = EnvelopeState.DECAY
                    self.state_start_time = self.current_time
                    
            elif self.state == EnvelopeState.DECAY:
                # Decay phase
                if self.current_level > self.sustain_level:
                    self.current_level -= self.decay_rate
                    if self.current_level <= self.sustain_level:
                        self.current_level = self.sustain_level
                        self.state = EnvelopeState.SUSTAIN
                        
            elif self.state == EnvelopeState.RELEASE:
                # Release phase
                self.current_level -= self.release_rate
                if self.current_level <= 0.0:
                    self.current_level = 0.0
                    self.state = EnvelopeState.IDLE
            
            samples[i] = self.current_level
            self.current_time += 1.0 / self.sample_rate
            
        return samples

class VoiceEnvelope:
    """Envelope with voice allocation management"""
    def __init__(self, num_voices: int = 8, sample_rate: int = 44100):
        self.num_voices = num_voices
        self.envelopes = [ADSREnvelope(sample_rate) for _ in range(num_voices)]
        self.active_voices = {}  # note -> envelope mapping
        
    def set_parameters(self, attack: float, decay: float, sustain: float, release: float):
        """Set ADSR parameters for all envelopes"""
        for env in self.envelopes:
            env.set_attack(attack)
            env.set_decay(decay)
            env.set_sustain(sustain)
            env.set_release(release)
    
    def note_on(self, note: int):
        """Start envelope for a note"""
        # Find free envelope or steal the oldest one
        envelope = None
        for env in self.envelopes:
            if env not in self.active_voices.values():
                envelope = env
                break
        
        if envelope is None:
            # No free envelopes, steal the first one
            envelope = self.envelopes[0]
            
        envelope.note_on()
        self.active_voices[note] = envelope
        
    def note_off(self, note: int):
        """Release envelope for a note"""
        if note in self.active_voices:
            self.active_voices[note].note_off()
            del self.active_voices[note]
    
    def generate_samples(self, num_samples: int) -> np.ndarray:
        """Generate envelope samples for all active voices"""
        if not self.active_voices:
            return np.zeros(num_samples)
            
        samples = np.zeros(num_samples)
        for envelope in self.active_voices.values():
            samples += envelope.generate_samples(num_samples)
            
        # Normalize
        if len(self.active_voices) > 1:
            samples /= len(self.active_voices)
            
        return samples
