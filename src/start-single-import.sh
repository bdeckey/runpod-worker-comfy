#!/usr/bin/env bash

# Use libtcmalloc for better memory management
TCMALLOC="$(ldconfig -p | grep -Po "libtcmalloc.so.\d" | head -n 1)"
export LD_PRELOAD="${TCMALLOC}"

# --- Define the path ON THE VOLUME where custom node folders actually live ---
NODE_PATH_ON_VOLUME="/runpod-volume/custom_nodes/ComfyUI-load-image-from-url" # Ensure this is correct

# --- Define the path INSIDE the default custom_nodes dir where we'll create the link ---
# Using a subdirectory name makes it cleaner than linking the volume root directly
LINK_TARGET_IN_CONTAINER="/comfyui/custom_nodes"

# --- Create the symbolic link at startup ---
# Check if the source directory on the volume exists
if [ -d "$NODE_PATH_ON_VOLUME" ]; then
    echo "runpod-worker-comfy: Found node directory on volume: $NODE_PATH_ON_VOLUME"
    # Create the parent directory for the link if it doesn't exist (it should)
    # mkdir -p "$(dirname "$LINK_TARGET_IN_CONTAINER")"
    # Create/update the symbolic link (-f forces overwrite if link already exists)
    # This links the volume path INTO the default custom_nodes directory
    ln -sf "$NODE_PATH_ON_VOLUME" "$LINK_TARGET_IN_CONTAINER"
    echo "runpod-worker-comfy: Created symlink: $LINK_TARGET_IN_CONTAINER -> $NODE_PATH_ON_VOLUME"
else
    echo "runpod-worker-comfy: Warning - Node directory not found on volume: $NODE_PATH_ON_VOLUME"
fi

# --- Original ComfyUI launch commands (NO --extra-node-paths needed) ---
# Construct base arguments (without the extra paths argument)
BASE_COMFYUI_ARGS="--disable-auto-launch --disable-metadata"

# Serve the API and don't shutdown the container
if [ "$SERVE_API_LOCALLY" == "true" ]; then
    COMFYUI_ARGS_FINAL="$BASE_COMFYUI_ARGS --listen"
    echo "runpod-worker-comfy: Starting ComfyUI with args: $COMFYUI_ARGS_FINAL"
    python3 /comfyui/main.py $COMFYUI_ARGS_FINAL &

    echo "runpod-worker-comfy: Starting RunPod Handler"
    python3 -u /rp_handler.py --rp_serve_api --rp_api_host=0.0.0.0
else
    COMFYUI_ARGS_FINAL="$BASE_COMFYUI_ARGS"
    echo "runpod-worker-comfy: Starting ComfyUI with args: $COMFYUI_ARGS_FINAL"
    python3 /comfyui/main.py $COMFYUI_ARGS_FINAL &

    echo "runpod-worker-comfy: Starting RunPod Handler"
    python3 -u /rp_handler.py
fi
