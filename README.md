# Bimanual Battery Picker

A bimanual robot manipulation system using two SO100 arms and an ACT (Action Chunking with Transformers) policy trained on 351 human demonstrations. The robot autonomously picks up a battery and places it into a basket using visual observations from three cameras.

**Course:** TECHIN 517 — University of Washington

**Video Demo:** [VIDEO LINK — TODO]

---

## System Overview

```
Camera Images (left wrist + right wrist + overhead)
        ↓
    ACT Policy (ResNet18 + Transformer)
        ↓
  Joint Actions (12-DOF bimanual control)
        ↓
  SO100 Bimanual Follower Arms
```

The system uses a single end-to-end learned policy that takes RGB images from three cameras and the current joint state as input, and outputs 12-DOF joint commands for both arms simultaneously.

## Hardware

- 2× SO100 follower arms (left + right)
- 2× SO100 leader arms for teleoperation/data collection
- 2× USB webcams (left wrist + right wrist)
- 1× Intel RealSense D435 (overhead, serial: 348522076012)
- NVIDIA GPU (tested on RTX 5090)

## Model

The trained ACT policy is available on HuggingFace:

**[https://huggingface.co/alannur/bimanual-battery-picker-act](https://huggingface.co/alannur/bimanual-battery-picker-act)**

To download:
```bash
hf download alannur/bimanual-battery-picker-act --local-dir outputs/train/act-bimanual-battery-v4/checkpoints/last/pretrained_model
```

### Training details

| Parameter | Value |
|---|---|
| Policy | ACT (Action Chunking with Transformers) |
| Backbone | ResNet18 |
| Demonstrations | 351 episodes |
| Training steps | 100,000 |
| Action chunk size | 100 |
| Cameras | left_wrist, right_wrist, overhead |
| Image resolution | 640×480 |

## Quantitative Results

Results from 15 evaluation trials across 3 battery positions:

| Condition | Trials | Success Rate | Avg Time (s) | Notes |
|---|---|---|---|---|
| Center position | 5 | — | — | — |
| Shifted left 5cm | 5 | — | — | — |
| Shifted right 5cm | 5 | — | — | — |

Raw trial data: [`results/trials.csv`](results/trials.csv)

**TODO: fill in results after completing evaluation runs**

## Setup

### Prerequisites

- Docker with NVIDIA GPU support (`nvidia-container-toolkit`)
- VS Code with the Dev Containers extension
- Ubuntu host machine (tested on 22.04 / 24.04)

### 1. Clone the repo

```bash
git clone https://github.com/<username>/bimanual-battery-picker.git
cd bimanual-battery-picker
```

### 2. Open in dev container

Open the folder in VS Code and click **Reopen in Container** when prompted.

The container will automatically:
- Install LeRobot and all dependencies
- Set up CUDA, ROS2 Humble, and RealSense drivers
- Link the HuggingFace cache to persistent storage

### 3. Download the pretrained model

```bash
huggingface-cli download <username>/bimanual-battery-picker-act \
  --local-dir outputs/train/act-bimanual-battery-v4/checkpoints/last/pretrained_model
```

### 4. Check USB ports and cameras

```bash
ls /dev/ttyACM*
v4l2-ctl --list-devices
```

Expected port mapping (may vary — replug one at a time to confirm):
- `follower1 (left arm)` → `/dev/ttyACM3`
- `follower2 (right arm)` → `/dev/ttyACM1`

Expected cameras (RealSense can shift video numbers — always recheck):
- Left wrist (Web Camera) → `/dev/video0`
- Right wrist (XWF-1080P) → `/dev/video2`
- Overhead → RealSense serial `348522076012`

## Usage

### Run the policy (eval)

```bash
bash scripts/eval.sh
```

Or with a custom checkpoint:

```bash
bash scripts/eval.sh /path/to/checkpoint eval_run_name
```

**Before each run:**
1. Give USB permissions: `sudo chmod 666 /dev/ttyACM0 /dev/ttyACM1 /dev/ttyACM2 /dev/ttyACM3`
2. Force cameras into MJPG mode:
   ```bash
   v4l2-ctl --device=/dev/video0 --set-fmt-video=width=640,height=480,pixelformat=MJPG --set-parm=30
   v4l2-ctl --device=/dev/video2 --set-fmt-video=width=640,height=480,pixelformat=MJPG --set-parm=30
   ```
3. During each episode the robot moves autonomously for `episode_time_s` seconds
4. During reset time, manually return the robot and battery to the starting position

### Train from scratch

```bash
bash scripts/train.sh
```

Requires the `battery-picker` dataset at `outputs/record/battery-picker/`.

## Repository Structure

```
bimanual-battery-picker/
├── .devcontainer/
│   └── devcontainer.json       # VS Code dev container config
├── docker/
│   ├── Dockerfile              # CUDA + ROS2 + LeRobot image
│   └── setup.sh                # Container init script
├── scripts/
│   ├── eval.sh                 # Run policy on real robot
│   └── train.sh                # Train ACT policy
├── results/
│   └── trials.csv              # Quantitative evaluation data
├── LICENSE
└── README.md
```

## Team Contributions

| Member | Contributions |
|---|---|
| Alan Nur | Robot setup, data collection, training pipeline, evaluation |
| Fan Zhang | Data collection, evaluation, results analysis |
| Wei Chang | Data collection, evaluation, results analysis |

## Acknowledgements

This project builds on:

- [LeRobot](https://github.com/huggingface/lerobot) (Apache 2.0) — robot learning framework
- [ACT](https://github.com/tonyzhaozh/act) — Action Chunking with Transformers policy
- [ROS2 Humble](https://docs.ros.org/en/humble/) — robot middleware
- SO100/SO101 robot arms by Feetech
- TECHIN 517 course materials — University of Washington

## License

Apache 2.0 — see [LICENSE](LICENSE).
