# src/nami/mixer/mixer.py

import numpy as np
from typing import Dict, Optional, List
import threading

class AudioChannel:
    """Single audio channel with volume and pan control"""
    def __init__(self, sample_rate: int = 44100):
        self.sample_rate = sample_rate
        self.volume = 1.0
        self.pan = 0.0  # -1.0 (left) to 1.0 (right)
        self.muted = False
        self.source = None  # Audio source (oscillator, etc.)
        
        # Volume ramping for smooth transitions
        self.target_volume = 1.0
        self.volume_ramp_samples = 0
        self.volume_increment = 0.0
        
        # Pan ramping
        self.target_pan = 0.0
        self.pan_ramp_samples = 0
        self.pan_increment = 0.0
    
    def set_volume(self, volume: float, ramp_ms: float = 10.0):
        """Set channel volume with optional ramping"""
        self.target_volume = max(0.0, min(2.0, volume))  # Allow slight boost
        if ramp_ms > 0:
            self.volume_ramp_samples = int(ramp_ms * self.sample_rate / 1000)
            self.volume_increment = (self.target_volume - self.volume) / self.volume_ramp_samples
        else:
            self.volume = self.target_volume
            self.volume_ramp_samples = 0
    
    def set_pan(self, pan: float, ramp_ms: float = 10.0):
        """Set channel pan position with optional ramping"""
        self.target_pan = max(-1.0, min(1.0, pan))
        if ramp_ms > 0:
            self.pan_ramp_samples = int(ramp_ms * self.sample_rate / 1000)
            self.pan_increment = (self.target_pan - self.pan) / self.pan_ramp_samples
        else:
            self.pan = self.target_pan
            self.pan_ramp_samples = 0
    
    def set_source(self, source):
        """Set audio source for this channel"""
        self.source = source
    
    def process_volume_ramp(self, num_samples: int):
        """Update volume ramping"""
        if self.volume_ramp_samples > 0:
            ramp_samples = min(num_samples, self.volume_ramp_samples)
            self.volume += self.volume_increment * ramp_samples
            self.volume_ramp_samples -= ramp_samples
            if self.volume_ramp_samples <= 0:
                self.volume = self.target_volume
    
    def process_pan_ramp(self, num_samples: int):
        """Update pan ramping"""
        if self.pan_ramp_samples > 0:
            ramp_samples = min(num_samples, self.pan_ramp_samples)
            self.pan += self.pan_increment * ramp_samples
            self.pan_ramp_samples -= ramp_samples
            if self.pan_ramp_samples <= 0:
                self.pan = self.target_pan
    
    def generate_samples(self, num_samples: int) -> np.ndarray:
        """Generate stereo samples with volume and pan applied"""
        if self.source is None or self.muted:
            return np.zeros((num_samples, 2))
            
        # Get mono samples from source
        mono_samples = self.source.generate_samples(num_samples)
        
        # Process volume and pan ramping
        self.process_volume_ramp(num_samples)
        self.process_pan_ramp(num_samples)
        
        # Calculate left/right gains based on pan position
        left_gain = self.volume * (1.0 - self.pan) / 2.0
        right_gain = self.volume * (1.0 + self.pan) / 2.0
        
        # Create stereo output
        stereo_samples = np.zeros((num_samples, 2))
        stereo_samples[:, 0] = mono_samples * left_gain
        stereo_samples[:, 1] = mono_samples * right_gain
        
        return stereo_samples

class Mixer:
    """Multi-channel audio mixer with volume control and panning"""
    def __init__(self, num_channels: int = 8, sample_rate: int = 44100):
        self.num_channels = num_channels
        self.sample_rate = sample_rate
        self.master_volume = 1.0
        
        # Channel management
        self.channels: Dict[int, AudioChannel] = {}
        self.next_channel_id = 0
        
        # Thread safety
        self.lock = threading.Lock()
        
        # Clipping prevention
        self.clip_threshold = 0.95
        self.soft_clip_range = 0.05
    
    def add_channel(self) -> int:
        """Add a new channel and return its ID"""
        with self.lock:
            channel_id = self.next_channel_id
            self.channels[channel_id] = AudioChannel(self.sample_rate)
            self.next_channel_id += 1
            return channel_id
    
    def remove_channel(self, channel_id: int):
        """Remove a channel"""
        with self.lock:
            if channel_id in self.channels:
                del self.channels[channel_id]
    
    def set_channel_volume(self, channel_id: int, volume: float, ramp_ms: float = 10.0):
        """Set channel volume"""
        if channel_id in self.channels:
            self.channels[channel_id].set_volume(volume, ramp_ms)
    
    def set_channel_pan(self, channel_id: int, pan: float, ramp_ms: float = 10.0):
        """Set channel pan position"""
        if channel_id in self.channels:
            self.channels[channel_id].set_pan(pan, ramp_ms)
    
    def set_channel_source(self, channel_id: int, source):
        """Set audio source for a channel"""
        if channel_id in self.channels:
            self.channels[channel_id].set_source(source)
    
    def set_master_volume(self, volume: float):
        """Set master volume"""
        self.master_volume = max(0.0, min(1.0, volume))
    
    def soft_clip(self, samples: np.ndarray) -> np.ndarray:
        """Apply soft clipping to prevent harsh distortion"""
        clip_start = self.clip_threshold
        clip_end = clip_start + self.soft_clip_range
        
        # Find samples that need clipping
        to_clip = np.abs(samples) > clip_start
        
        if np.any(to_clip):
            # Apply smooth curve to samples above threshold
            clip_samples = samples[to_clip]
            x = (np.abs(clip_samples) - clip_start) / self.soft_clip_range
            curve = 1.0 - (1.0 - x) ** 2
            clip_amount = clip_start + curve * self.soft_clip_range
            samples[to_clip] = np.sign(clip_samples) * clip_amount
        
        return samples
    
    def generate_samples(self, num_samples: int) -> np.ndarray:
        """Mix all channels and generate final stereo output"""
        # Initialize output buffer
        output = np.zeros((num_samples, 2))
        
        # Mix all active channels
        with self.lock:
            active_channels = len(self.channels)
            if active_channels == 0:
                return output
                
            for channel in self.channels.values():
                output += channel.generate_samples(num_samples)
            
            # Apply master volume
            output *= self.master_volume
            
            # Prevent clipping
            output = self.soft_clip(output)
            
            return output
