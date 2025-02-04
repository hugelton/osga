# src/nami/core/engine.py

import miniaudio
import numpy as np
from collections import deque
import threading
import time
from typing import Optional, Dict, Any
from .buffer import AudioBuffer
from ..mixer.mixer import Mixer

class DeviceManager:
    """Audio device management and configuration"""
    def __init__(self):
        self.device = None
        self.output_devices = []
        self._scan_devices()

    def _scan_devices(self):
        """Scan available audio output devices"""
        try:
            playback_devices = miniaudio.Devices()
            self.output_devices = playback_devices.get_playback_devices()
        except Exception as e:
            print(f"Error scanning audio devices: {e}")
            self.output_devices = []

    def get_default_device(self) -> Optional[Dict[str, Any]]:
        """Get default audio device information"""
        if self.output_devices:
            return self.output_devices[0]
        return None

    def create_device(self, config: Dict[str, Any]) -> Optional[miniaudio.PlaybackDevice]:
        """Create audio device with given configuration"""
        try:
            device = miniaudio.PlaybackDevice(
                output_format=miniaudio.SampleFormat.FLOAT32,
                nchannels=config.get('channels', 2),
                sample_rate=config.get('sample_rate', 44100),
                buffersize_msec=config.get('buffer_size_ms', 50),
            )
            return device
        except Exception as e:
            print(f"Error creating audio device: {e}")
            return None

class AudioEngine:
    """Core audio engine handling device management and audio processing"""
    def __init__(self):
        self.device_manager = DeviceManager()
        self.mixer = Mixer()
        
        # Engine configuration
        self.sample_rate = 44100
        self.channels = 2
        self.buffer_size = 1024
        self.running = False
        
        # Performance monitoring
        self.performance_metrics = {
            'cpu_load': 0.0,
            'buffer_underruns': 0,
            'latency_ms': 0.0,
            'peak_level': 0.0
        }
        
        # Thread management
        self.audio_thread = None
        self.processing_lock = threading.Lock()
        
        # Audio buffer management
        self.main_buffer = AudioBuffer(
            max_size=self.buffer_size * 4,
            channels=self.channels
        )
        
        # Processing chain
        self.processors = []
        
    def init(self, sample_rate: int = 44100, channels: int = 2, buffer_size: int = 1024) -> bool:
        """Initialize audio engine with given parameters"""
        try:
            self.sample_rate = sample_rate
            self.channels = channels
            self.buffer_size = buffer_size
            
            # Initialize device
            config = {
                'sample_rate': sample_rate,
                'channels': channels,
                'buffer_size_ms': int((buffer_size / sample_rate) * 1000)
            }
            
            device = self.device_manager.create_device(config)
            if device is None:
                return False
                
            self.device_manager.device = device
            device.callback = self._audio_callback
            
            # Initialize mixer
            self.mixer = Mixer(num_channels=8, sample_rate=sample_rate)
            
            # Reset buffer
            self.main_buffer = AudioBuffer(
                max_size=buffer_size * 4,
                channels=channels
            )
            
            return True
            
        except Exception as e:
            print(f"Error initializing audio engine: {e}")
            return False
            
    def _audio_callback(self, device, output_buffer, frame_count):
        """Real-time audio callback"""
        try:
            # Process audio in chunks
            with self.processing_lock:
                # Get mixed audio from mixer
                mixed_audio = self.mixer.generate_samples(frame_count)
                
                # Apply audio processors
                processed_audio = mixed_audio
                for processor in self.processors:
                    processed_audio = processor.process(processed_audio)
                
                # Update performance metrics
                self._update_metrics(processed_audio)
                
                # Write to output buffer
                output_buffer[:] = processed_audio.tobytes()
                
        except Exception as e:
            print(f"Audio callback error: {e}")
            # Fill with silence in case of error
            output_buffer[:] = np.zeros(frame_count * self.channels, dtype=np.float32).tobytes()
            self.performance_metrics['buffer_underruns'] += 1
            
    def _update_metrics(self, audio_data: np.ndarray):
        """Update performance metrics"""
        self.performance_metrics['peak_level'] = np.max(np.abs(audio_data))
        self.performance_metrics['latency_ms'] = (
            self.buffer_size / self.sample_rate * 1000
        )
        
    def add_processor(self, processor):
        """Add audio processor to the chain"""
        with self.processing_lock:
            self.processors.append(processor)
            
    def remove_processor(self, processor):
        """Remove audio processor from the chain"""
        with self.processing_lock:
            if processor in self.processors:
                self.processors.remove(processor)
                
    def start(self) -> bool:
        """Start audio processing"""
        try:
            if self.device_manager.device is None:
                return False
                
            self.device_manager.device.start()
            self.running = True
            return True
            
        except Exception as e:
            print(f"Error starting audio engine: {e}")
            return False
            
    def stop(self):
        """Stop audio processing"""
        try:
            if self.device_manager.device:
                self.device_manager.device.stop()
            self.running = False
            
        except Exception as e:
            print(f"Error stopping audio engine: {e}")
            
    def get_metrics(self) -> Dict[str, float]:
        """Get current performance metrics"""
        return self.performance_metrics.copy()
        
    def set_master_volume(self, volume: float):
        """Set master output volume"""
        self.mixer.set_master_volume(volume)
        
    def get_buffer_size(self) -> int:
        """Get current buffer size"""
        return self.buffer_size
        
    def get_sample_rate(self) -> int:
        """Get current sample rate"""
        return self.sample_rate
        
    def get_channels(self) -> int:
        """Get current number of channels"""
        return self.channels
        
    def __del__(self):
        """Cleanup resources"""
        self.stop()
        if hasattr(self, 'device_manager') and self.device_manager.device:
            self.device_manager.device.close()
