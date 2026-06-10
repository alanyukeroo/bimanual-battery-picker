#!/bin/bash
# Run trained ACT policy on the bimanual SO100 robot.
# Usage: bash scripts/eval.sh [CHECKPOINT_PATH] [EVAL_NAME]

CHECKPOINT=${1:-/home/ubuntu/bimanual-battery-picker/outputs/train/act-bimanual-battery-v4/checkpoints/last/pretrained_model}
EVAL_NAME=${2:-eval_run_$(date +%Y%m%d_%H%M%S)}

# USB permissions
sudo chmod 666 /dev/ttyACM0 /dev/ttyACM1 /dev/ttyACM2 /dev/ttyACM3

# Force wrist cameras into MJPG mode (RealSense can shift video device numbers)
# Adjust /dev/videoX based on your current v4l2-ctl --list-devices output
v4l2-ctl --device=/dev/video0 --set-fmt-video=width=640,height=480,pixelformat=MJPG --set-parm=30
v4l2-ctl --device=/dev/video2 --set-fmt-video=width=640,height=480,pixelformat=MJPG --set-parm=30

rm -rf /home/ubuntu/bimanual-battery-picker/outputs/eval/${EVAL_NAME}

lerobot-record \
  --robot.type=bi_so100_follower \
  --robot.left_arm_port=/dev/ttyACM3 \
  --robot.right_arm_port=/dev/ttyACM1 \
  --robot.id=bimanual_follower \
  --robot.cameras="{left_wrist: {type: opencv, index_or_path: /dev/video0, width: 640, height: 480, fps: 30, fourcc: MJPG}, right_wrist: {type: opencv, index_or_path: /dev/video2, width: 640, height: 480, fps: 30, fourcc: MJPG}, overhead: {type: intelrealsense, serial_number_or_name: 348522076012, width: 1280, height: 720, fps: 30}}" \
  --policy.path=${CHECKPOINT} \
  --dataset.repo_id=local/${EVAL_NAME} \
  --dataset.root=/home/ubuntu/bimanual-battery-picker/outputs/eval/${EVAL_NAME} \
  --dataset.push_to_hub=false \
  --dataset.num_episodes=5 \
  --dataset.single_task="pick up the battery and put it into the basket" \
  --dataset.episode_time_s=30 \
  --dataset.reset_time_s=5 \
  --dataset.num_image_writer_processes=1 \
  --dataset.num_image_writer_threads_per_camera=1 \
  --display_data=false \
  --play_sounds=false
