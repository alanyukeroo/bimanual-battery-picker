#!/bin/bash

# Create XDG_RUNTIME_DIR for GUI apps like Rerun
export XDG_RUNTIME_DIR=/tmp/runtime-ubuntu
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

# USB latency fix for serial devices
for tty in /sys/bus/usb-serial/devices/*/latency_timer; do
    if [ -f "$tty" ]; then
        echo 1 | sudo tee "$tty" > /dev/null 2>&1 || true
    fi
done

# Increase USB buffer sizes for better stability
sudo sh -c 'echo 16777216 > /proc/sys/net/core/rmem_max' 2>/dev/null || true
sudo sh -c 'echo 16777216 > /proc/sys/net/core/wmem_max' 2>/dev/null || true

# V4L2 camera buffer settings (helps with camera timeouts)
for video_dev in /dev/video*; do
    if [ -c "$video_dev" ]; then
        sudo chmod 666 "$video_dev" 2>/dev/null || true
    fi
done

# Link huggingface cache to persistent storage
PERSISTENT_HF_DIR="/home/ubuntu/bimanual-battery-picker/huggingface"
HF_CACHE_DIR="/home/ubuntu/.cache/huggingface"

mkdir -p "$PERSISTENT_HF_DIR"
mkdir -p "$(dirname "$HF_CACHE_DIR")"

if [ -L "$HF_CACHE_DIR" ]; then
    if [ "$(readlink "$HF_CACHE_DIR")" != "$PERSISTENT_HF_DIR" ]; then
        rm "$HF_CACHE_DIR"
        ln -s "$PERSISTENT_HF_DIR" "$HF_CACHE_DIR"
    fi
elif [ -d "$HF_CACHE_DIR" ]; then
    cp -rn "$HF_CACHE_DIR"/* "$PERSISTENT_HF_DIR"/ 2>/dev/null || true
    rm -rf "$HF_CACHE_DIR"
    ln -s "$PERSISTENT_HF_DIR" "$HF_CACHE_DIR"
else
    ln -s "$PERSISTENT_HF_DIR" "$HF_CACHE_DIR"
fi

# Install LeRobot
pip install 'lerobot[all]'
pip uninstall torch torchvision torchaudio -y
pip install torch==2.7.1 torchvision==0.22.1 torchaudio==2.7.1 --index-url https://download.pytorch.org/whl/cu128
