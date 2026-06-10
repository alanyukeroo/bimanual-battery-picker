# Battery Sorting Robot

An imitation learning system for bimanual battery sorting using the ACT (Action Chunking with Transformers) policy trained on 351 teleoperation demonstrations. The robot picks a target battery from a pile of objects and places it into a basket, achieving **86% average success rate** across 200 evaluation trials.

**Course:** TECHIN 517 — University of Washington, Spring 2026  
**Team:** Alan Nur · Fan Zhang · Wei Chang

**Video Demo:** [VIDEO LINK — TODO]  
**Pretrained Model:** [huggingface.co/alannur/bimanual-battery-picker-act](https://huggingface.co/alannur/bimanual-battery-picker-act)

---

## The Task

Pick a target battery from a pile of objects and place it into a basket. Full cycle < 5 seconds.

| Step | Description |
|---|---|
| 1. Pull Basket | Left arm grabs the basket and pulls it closer to the workspace |
| 2. Pick Battery | Right arm identifies and grasps the target battery from the pile |
| 3. Place & Reset | Right arm places battery into basket, both arms return to home |

## System Overview

```
Teleoperation  →  Data Pipeline  →  ACT Training  →  Deployment
SO-ARM101          351 episodes      LeRobot            Autonomous
Leader/Follower    Dual cameras      RTX 5090           inference
```

**End-to-end pipeline:** human teleoperation demos → ACT policy training → autonomous deployment on real hardware. No reinforcement learning.

## Quantitative Results

200 evaluation trials across 4 test conditions (50 trials each):

| Condition | Trials | Success | Success Rate |
|---|---|---|---|
| Single Battery (clean workspace) | 50 | 45 | **90%** |
| Distractors — In Dataset | 50 | 45 | **90%** |
| Distractors — Out of Dataset | 50 | 40 | **80%** |
| Similar Batteries | 50 | 42 | **84%** |
| **Overall** | **200** | **172** | **86%** |

### Before vs After (Presentation 2 → Final)

| Metric | Presentation 2 | Final | Change |
|---|---|---|---|
| Episodes | 130 | 351 | +170% |
| Single battery | 80% | 90% | +10pp |
| In-dataset distractors | 60% | 90% | +30pp |
| Out-of-dataset distractors | 20% | 80% | **+60pp** |

> Key insight: **data diversity is more impactful than data volume**. The generalization gap closed from 20% → 80% on unseen layouts.

Raw trial data: [`results/trials.csv`](results/trials.csv)

## Training Details

| Parameter | Value |
|---|---|
| Policy | ACT (Action Chunking with Transformers) |
| Backbone | ResNet18 |
| Framework | LeRobot |
| Demonstrations | 351 episodes |
| Training steps | 100,000 |
| Training time | ~3 hours |
| Hardware | NVIDIA RTX 5090 |
| Action chunk size | 100 |
| Cameras | Overhead (RealSense) + Wrist RGB |
| Image resolution | 640×480 |

ACT predicts a sequence of future actions from visual observations, enabling smooth and coordinated bimanual manipulation without reinforcement learning.

### Dataset Composition (351 episodes)

| Subset | Description |
|---|---|
| Single Battery | Core task — one target battery on clean workspace |
| Varied Basket Positions | Basket placed in multiple locations |
| Distracting Objects | Non-target objects from within and outside the training set |
| Similar Batteries | Other battery types to test discrimination ability |

## Hardware

- 2× SO100 follower arms (left + right)
- 2× SO100 leader arms for teleoperation / data collection
- 2× USB webcams (left wrist + right wrist)
- 1× Intel RealSense D435 overhead camera (serial: 348522076012)
- NVIDIA RTX 5090 for training and inference

## Setup

### Prerequisites

- Docker with NVIDIA GPU support (`nvidia-container-toolkit`)
- VS Code with the Dev Containers extension
- Ubuntu host machine (tested on 22.04 / 24.04)

### 1. Clone the repo

```bash
git clone https://github.com/alanyukeroo/bimanual-battery-picker.git
cd bimanual-battery-picker
```

### 2. Open in dev container

Open the folder in VS Code and click **Reopen in Container** when prompted.

The container will automatically:
- Install LeRobot and all dependencies
- Set up CUDA 12.4, ROS2 Humble, and RealSense drivers
- Link the HuggingFace cache to persistent storage

### 3. Download the pretrained model

```bash
hf download alannur/bimanual-battery-picker-act \
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

Expected cameras (RealSense can shift video device numbers — always recheck with `v4l2-ctl --list-devices`):
- Left wrist camera → `/dev/video0`
- Right wrist camera → `/dev/video2`
- Overhead RealSense → serial `348522076012`

## Usage

### Run the policy

```bash
bash scripts/eval.sh
```

Or with a custom checkpoint and run name:

```bash
bash scripts/eval.sh /path/to/checkpoint my_eval_run
```

**Before each run:**

```bash
# 1. USB permissions
sudo chmod 666 /dev/ttyACM0 /dev/ttyACM1 /dev/ttyACM2 /dev/ttyACM3

# 2. Force wrist cameras into MJPG mode
v4l2-ctl --device=/dev/video0 --set-fmt-video=width=640,height=480,pixelformat=MJPG --set-parm=30
v4l2-ctl --device=/dev/video2 --set-fmt-video=width=640,height=480,pixelformat=MJPG --set-parm=30
```

During each episode the robot moves autonomously for `episode_time_s` seconds. During reset time, manually return the robot and battery to the starting position.

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
│   ├── Dockerfile              # CUDA 12.4 + ROS2 Humble + LeRobot
│   └── setup.sh                # Container init script
├── scripts/
│   ├── eval.sh                 # Run policy on real robot
│   └── train.sh                # Train ACT policy
├── results/
│   └── trials.csv              # Quantitative evaluation data (200 trials)
├── LICENSE                     # Apache 2.0
└── README.md
```

## Challenges & Solutions

| Challenge | Solution |
|---|---|
| Poor generalization — policy memorized specific scene layouts | Expanded dataset from 130 → 351 episodes with varied positions, objects, and backgrounds |
| Weak error recovery — robot repeated wrong motions after failed grasps | Collected recovery demonstrations showing how to correct mistakes mid-task |
| Inaccurate grasping on unfamiliar layouts | Added close-up grasp examples and diverse object orientations to training set |

## Team Contributions

| Member | Contributions |
|---|---|
| Alan Nur | Teleoperation · Training · Evaluation |
| Fan Zhang | Teleoperation · Training · Evaluation |
| Wei Chang | Teleoperation · Training · Evaluation |

## Acknowledgements

This project builds on:

- [LeRobot](https://github.com/huggingface/lerobot) (Apache 2.0) — robot learning framework
- [ACT](https://github.com/tonyzhaozh/act) — Action Chunking with Transformers
- [ROS2 Humble](https://docs.ros.org/en/humble/) — robot middleware
- SO100/SO101 robot arms by Feetech
- TECHIN 517 course materials — University of Washington

## License

Apache 2.0 — see [LICENSE](LICENSE).
