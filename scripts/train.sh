#!/bin/bash
# Train ACT policy on the bimanual battery-picker dataset.
# Usage: bash scripts/train.sh [OUTPUT_DIR]

OUTPUT_DIR=${1:-/home/ubuntu/bimanual-battery-picker/outputs/train/act-bimanual-battery-v4}

PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True lerobot-train \
  --policy.type=act \
  --dataset.repo_id=local/battery-picker \
  --dataset.root=/home/ubuntu/bimanual-battery-picker/outputs/record/battery-picker \
  --output_dir=${OUTPUT_DIR} \
  --policy.push_to_hub=false \
  --policy.device=cuda \
  --steps=100000 \
  --batch_size=8 \
  --num_workers=4
