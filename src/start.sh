#!/usr/bin/env bash

# Use libtcmalloc for better memory management
TCMALLOC="$(ldconfig -p | grep -Po "libtcmalloc.so.\d" | head -n 1)"
export LD_PRELOAD="${TCMALLOC}"

# --- Define the PARENT path ON THE VOLUME where custom node folders live ---
SOURCE_PARENT_DIR="/runpod-volume/custom_nodes"

# --- Define the PARENT path INSIDE the container where links should be created ---
TARGET_PARENT_DIR="/comfyui/custom_nodes"

# --- Ensure the target directory exists ---
# This is usually present in the ComfyUI image, but good practice to ensure
mkdir -p "$TARGET_PARENT_DIR"
echo "runpod-worker-comfy: Ensured target directory exists: $TARGET_PARENT_DIR"

# --- Create symbolic links for all directories found in the source ---
# Check if the source parent directory on the volume exists
if [ -d "$SOURCE_PARENT_DIR" ]; then
    echo "runpod-worker-comfy: Found source node directory on volume: $SOURCE_PARENT_DIR"

    # Loop through each item (file or directory) in the source directory
    for item_path_on_volume in "$SOURCE_PARENT_DIR"/*; do
        # Check if the item is actually a directory
        if [ -d "$item_path_on_volume" ]; then
            # Get the base name of the directory (e.g., "ComfyUI-load-image-from-url")
            item_name=$(basename "$item_path_on_volume")
            # Construct the full path for the symbolic link inside the container
            link_target_in_container="$TARGET_PARENT_DIR/$item_name"

            # Create/update the symbolic link (-f forces overwrite if link already exists)
            # This links the specific node directory from the volume INTO the default custom_nodes directory
            ln -sf "$item_path_on_volume" "$link_target_in_container"
            echo "runpod-worker-comfy: Created symlink: $link_target_in_container -> $item_path_on_volume"
        else
             echo "runpod-worker-comfy: Skipping non-directory item: $item_path_on_volume"
        fi
    done
    echo "runpod-worker-comfy: Finished processing custom nodes from volume."

else
    echo "runpod-worker-comfy: Warning - Source node directory not found on volume: $SOURCE_PARENT_DIR. No custom nodes linked."
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
