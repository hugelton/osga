# src/nami/core/buffer.py

import numpy as np
from collections import deque
import threading
from typing import Optional, Tuple

class AudioBuffer:
    """Thread-safe audio buffer with overflow protection"""
    def __init__(self, max_size: int = 4096, channels: int = 2):
        self.max_size = max_size
        self.channels = channels
        self.buffer = deque(maxlen=max_size)
        self.lock = threading.Lock()
        
        # Performance monitoring
        self.overflow_count = 0
        self.underflow_count = 0
        
    def write(self, data: np.ndarray) -> int:
        """Write audio data to buffer, returns number of samples written"""
        with self.lock:
            available_space = self.max_size - len(self.buffer)
            if available_space <= 0:
                self.overflow_count += 1
                return 0
                
            # Ensure data is in correct format
            if len(data.shape) == 1:
                data = data.reshape(-1, self.channels)
                
            samples_to_write = min(len(data), available_space)
            for i in range(samples_to_write):
                self.buffer.append(data[i])
                
            return samples_to_write
            
    def read(self, num_samples: int) -> np.ndarray:
        """Read specified number of samples from buffer"""
        with self.lock:
            if len(self.buffer) < num_samples:
                self.underflow_count += 1
                # Return silence if not enough samples
                return np.zeros((num_samples, self.channels), dtype=np.float32)
                
            # Read requested samples
            samples = []
            for _ in range(num_samples):
                samples.append(self.buffer.popleft())
                
            return np.array(samples)
            
    def peek(self, num_samples: int) -> np.ndarray:
        """Read samples without removing them from buffer"""
        with self.lock:
            if len(self.buffer) < num_samples:
                return np.zeros((num_samples, self.channels), dtype=np.float32)
                
            return np.array(list(self.buffer)[:num_samples])
            
    def clear(self):
        """Clear all samples from buffer"""
        with self.lock:
            self.buffer.clear()
            
    def get_available_samples(self) -> int:
        """Get number of available samples in buffer"""
        with self.lock:
            return len(self.buffer)
            
    def get_metrics(self) -> dict:
        """Get buffer performance metrics"""
        with self.lock:
            return {
                'size': len(self.buffer),
                'max_size': self.max_size,
                'overflow_count': self.overflow_count,
                'underflow_count': self.underflow_count,
                'utilization': len(self.buffer) / self.max_size
            }

class RingBuffer:
    """Lock-free ring buffer for audio processing"""
    def __init__(self, size: int, channels: int = 2):
        self.size = size
        self.channels = channels
        self.buffer = np.zeros((size, channels), dtype=np.float32)
        self.write_pos = 0
        self.read_pos = 0
        
    def write(self, data: np.ndarray) -> int:
        """Write data to ring buffer"""
        if len(data.shape) == 1:
            data = data.reshape(-1, self.channels)
            
        samples_to_write = min(len(data), self.size - self.get_available_samples())
        if samples_to_write <= 0:
            return 0
            
        # Write data in two parts if necessary
        first_write = min(samples_to_write, self.size - self.write_pos)
        self.buffer[self.write_pos:self.write_pos + first_write] = data[:first_write]
        
        if first_write < samples_to_write:
            # Wrap around and write remaining samples
            remaining = samples_to_write - first_write
            self.buffer[:remaining] = data[first_write:samples_to_write]
            self.write_pos = remaining
        else:
            self.write_pos = (self.write_pos + first_write) % self.size
            
        return samples_to_write
        
    def read(self, num_samples: int) -> np.ndarray:
        """Read data from ring buffer"""
        available = self.get_available_samples()
        if available < num_samples:
            return np.zeros((num_samples, self.channels), dtype=np.float32)
            
        # Read data in two parts if necessary
        result = np.zeros((num_samples, self.channels), dtype=np.float32)
        first_read = min(num_samples, self.size - self.read_pos)
        result[:first_read] = self.buffer[self.read_pos:self.read_pos + first_read]
        
        if first_read < num_samples:
            # Wrap around and read remaining samples
            remaining = num_samples - first_read
            result[first_read:] = self.buffer[:remaining]
            self.read_pos = remaining
        else:
            self.read_pos = (self.read_pos + first_read) % self.size
            
        return result
        
    def get_available_samples(self) -> int:
        """Get number of available samples"""
        return (self.write_pos - self.read_pos) % self.size
        
    def clear(self):
        """Clear buffer contents"""
        self.buffer.fill(0)
        self.write_pos = 0
        self.read_pos = 0

class DelayBuffer:
    """Specialized buffer for delay-based effects"""
    def __init__(self, max_delay_samples: int, channels: int = 2):
        self.max_delay = max_delay_samples
        self.channels = channels
        self.buffer = np.zeros((max_delay_samples, channels), dtype=np.float32)
        self.write_pos = 0
        
    def write_sample(self, sample: np.ndarray):
        """Write single sample to delay buffer"""
        self.buffer[self.write_pos] = sample
        self.write_pos = (self.write_pos + 1) % self.max_delay
        
    def read_delayed(self, delay_samples: int) -> np.ndarray:
        """Read delayed sample from buffer"""
        if delay_samples >= self.max_delay:
            return np.zeros(self.channels, dtype=np.float32)
            
        read_pos = (self.write_pos - delay_samples) % self.max_delay
        return self.buffer[read_pos]
        
    def clear(self):
        """Clear delay buffer"""
        self.buffer.fill(0)
