# src/koto/koto.py
from RPi_GPIO_Rotary import rotary
import RPi.GPIO as GPIO
import json
import time


class Koto:
    def __init__(self):
        """Initialize hardware interface"""
        # GPIO の初期化
        GPIO.setwarnings(False)
        GPIO.cleanup()
        GPIO.setmode(GPIO.BCM)

        # 設定の読み込み
        with open("gpio.json", "r") as f:
            self.config = json.load(f)

        # 状態の初期化
        self.count = 0
        self.rotary_button = False
        self.is_running = False

        # ボタンの状態
        self.buttons = {
            "x": {"pressed": False, "long_press": False, "press_time": 0},
            "y": {"pressed": False, "long_press": False, "press_time": 0},
            "z": {"pressed": False, "long_press": False, "press_time": 0},
        }
        self.long_press_threshold = 0.5  # 500ms for long press

        # ハードウェアの初期化
        self._init_rotary()
        self._init_buttons()
        self._init_backlight()

    def _init_rotary(self):
        """Initialize rotary encoder"""
        try:
            self.encoder = rotary.Rotary(
                self.config["rotary"]["clk"],
                self.config["rotary"]["dt"],
                self.config["rotary"]["sw"],
                2,  # ticks per step
            )
            self.encoder.register(
                increment=self._on_cw,
                decrement=self._on_ccw,
                pressed=self._on_rotary_button,
                onchange=self._on_value_change,
            )
        except Exception as e:
            print(f"Rotary encoder initialization error: {e}")
            self.encoder = None

    def _init_buttons(self):
        """Initialize push buttons"""
        for button_name, pin in self.config["buttons"].items():
            try:
                # 既存のイベント検出をクリア
                try:
                    GPIO.remove_event_detect(pin)
                except:
                    pass

                GPIO.setup(pin, GPIO.IN, pull_up_down=GPIO.PUD_UP)
                GPIO.add_event_detect(
                    pin,
                    GPIO.BOTH,
                    callback=lambda channel, btn=button_name: self._handle_button_event(
                        btn, channel
                    ),
                    bouncetime=50,
                )
            except Exception as e:
                print(
                    f"Warning: Could not set up button {button_name} on pin {pin}: {e}"
                )

    def _init_backlight(self):
        """Initialize LCD backlight"""
        try:
            self.backlight_pin = self.config["display"]["backlight"]
            GPIO.setup(self.backlight_pin, GPIO.OUT)
            self.backlight_pwm = GPIO.PWM(self.backlight_pin, 100)  # 100Hz
            self.backlight_pwm.start(100)  # Start at 100% brightness
            self.current_brightness = 255
        except Exception as e:
            print(f"Backlight initialization error: {e}")
            self.backlight_pwm = None

    def _on_cw(self):
        """Clockwise rotation handler"""
        self.count += 1

    def _on_ccw(self):
        """Counter-clockwise rotation handler"""
        self.count -= 1

    def _on_rotary_button(self):
        """Rotary encoder button handler"""
        self.rotary_button = not self.rotary_button

    def _on_value_change(self, value):
        """Value change handler"""
        self.count = value

    def _handle_button_event(self, button_name, channel):
        """Handle button events"""
        current_state = not GPIO.input(channel)  # Inverted because of pull-up
        current_time = time.time()

        if current_state:  # Button pressed
            self.buttons[button_name]["pressed"] = True
            self.buttons[button_name]["press_time"] = current_time
            self.buttons[button_name]["long_press"] = False
        else:  # Button released
            if self.buttons[button_name]["pressed"]:
                press_duration = current_time - self.buttons[button_name]["press_time"]
                self.buttons[button_name]["long_press"] = (
                    press_duration >= self.long_press_threshold
                )
            self.buttons[button_name]["pressed"] = False

    def get_state(self):
        """Get current state of all inputs"""
        return {
            "rotary": {"count": self.count, "button": self.rotary_button},
            "buttons": {
                name: {"pressed": state["pressed"], "long_press": state["long_press"]}
                for name, state in self.buttons.items()
            },
        }

    def set_backlight(self, brightness: int):
        """Set LCD backlight brightness (0-255)"""
        if self.backlight_pwm:
            self.current_brightness = max(0, min(255, brightness))
            duty_cycle = (self.current_brightness / 255.0) * 100
            self.backlight_pwm.ChangeDutyCycle(duty_cycle)

    def get_backlight(self) -> int:
        """Get current backlight brightness"""
        return self.current_brightness

    def start(self):
        """Start monitoring"""
        if self.encoder and not self.is_running:
            try:
                self.encoder.start()
                self.is_running = True
            except Exception as e:
                print(f"Failed to start rotary encoder: {e}")

    def stop(self):
        """Stop monitoring and cleanup"""
        if self.encoder and self.is_running:
            try:
                self.encoder.stop()
                self.is_running = False
            except Exception as e:
                print(f"Error stopping rotary encoder: {e}")

        if hasattr(self, "backlight_pwm") and self.backlight_pwm:
            try:
                self.backlight_pwm.stop()
            except:
                pass

    def __del__(self):
        """Cleanup"""
        self.stop()
        try:
            GPIO.cleanup()
        except:
            pass
