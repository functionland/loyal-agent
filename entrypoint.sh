#!/bin/bash

# Set file descriptor limits using ulimit
ulimit -n 1048576

# Default values for parameters
TARGET_PLATFORM=${TARGET_PLATFORM:-"rk3588"}
RKLLM_MODEL_PATH=${RKLLM_MODEL_PATH:-"/uniondrive/loyal-agent/model/deepseek-llm-7b-chat-rk3588-w8a8_g256-opt-1-hybrid-ratio-0.5.rkllm"}

# Run the Python application with provided or default parameters
exec python3 /app/app.py --target_platform "$TARGET_PLATFORM" --rkllm_model_path "$RKLLM_MODEL_PATH"
