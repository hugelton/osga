# Commands

## fbcp との同期を改善するための設定

`sudo sh -c 'echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor'`

## カーソル点滅を無効化

`sudo sh -c 'echo 0 > /sys/class/graphics/fbcon/cursor_blink'`
