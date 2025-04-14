#!/usr/bin/env bash

# Use libtcmalloc for better memory management
TCMALLOC="$(ldconfig -p | grep -Po "libtcmalloc.so.\d" | head -n 1)"
export LD_PRELOAD="${TCMALLOC}"

# --- UPDATED: Define the path on the network volume for custom nodes ---
# This path should contain the cloned/copied custom node folders
# (e.g., /workspace/custom_nodes/ComfyUI-Manager, /workspace/custom_nodes/was-node-suite, etc.)
EXTRA_NODE_PATH_ON_VOLUME="/workspace/custom_nodes" # Changed to user's specified path

# --- MODIFIED: Construct base arguments for ComfyUI ---
# We add --extra-node-paths here so it applies in both cases below
BASE_COMFYUI_ARGS="--disable-auto-launch --disable-metadata"
if [ -d "$EXTRA_NODE_PATH_ON_VOLUME" ]; then
    echo "runpod-worker-comfy: Adding extra node path: $EXTRA_NODE_PATH_ON_VOLUME"
    # Ensure the path is quoted in case of spaces, though unlikely here
    BASE_COMFYUI_ARGS="$BASE_COMFYUI_ARGS --extra-node-paths \"$EXTRA_NODE_PATH_ON_VOLUME\""
else
    echo "runpod-worker-comfy: Warning - Extra node path directory not found: $EXTRA_NODE_PATH_ON_VOLUME"
fi


# Serve the API and don't shutdown the container
if [ "$SERVE_API_LOCALLY" == "true" ]; then
    # --- MODIFIED: Add --listen to base args and execute ---
    COMFYUI_ARGS_FINAL="$BASE_COMFYUI_ARGS --listen"
    echo "runpod-worker-comfy: Starting ComfyUI with args: $COMFYUI_ARGS_FINAL"
    python3 /comfyui/main.py $COMFYUI_ARGS_FINAL &

    echo "runpod-worker-comfy: Starting RunPod Handler"
    python3 -u /rp_handler.py --rp_serve_api --rp_api_host=0.0.0.0
else
    # --- MODIFIED: Execute with base args ---
    COMFYUI_ARGS_FINAL="$BASE_COMFYUI_ARGS"
    echo "runpod-worker-comfy: Starting ComfyUI with args: $COMFYUI_ARGS_FINAL"
    python3 /comfyui/main.py $COMFYUI_ARGS_FINAL &

    echo "runpod-worker-comfy: Starting RunPod Handler"
    python3 -u /rp_handler.py
fi
