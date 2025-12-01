#!/bin/bash

# =========================
# Cross-platform MADS Pipeline Launcher
# =========================

# Detect OS
OS="$(uname -s)"
echo "Detected OS: $OS"

# Check filter argument
FILTER_NAME="$1"
if [ -z "$FILTER_NAME" ]; then
    echo "Usage: ./run.sh <mads_filter_test | pose_estimation>"
    exit 1
fi

# -------------------------
# Function to run mads command in background
# -------------------------
run_mads() {
    CMD="$1"
    DIR="$2"
    case "$OS" in
        Darwin)
            osascript -e 'tell application "Terminal" to do script "cd '"$DIR"'; '"$CMD"'"'
            ;;
        Linux)
            gnome-terminal -- bash -c "cd '$DIR'; $CMD; exec bash"
            ;;
        MINGW*|MSYS*|CYGWIN*|Windows_NT)
            start cmd /k "cd /d '$DIR' && $CMD"
            ;;
        *)
            echo "Unsupported OS: $OS"
            ;;
    esac
}

# Base directory of script
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

# -------------------------
# 1) Start MADS broker
# -------------------------
echo "Starting MADS broker with configuration file..."
run_mads "mads broker -s mads.ini" "$BASE_DIR"
sleep 3

# -------------------------
# 2) Build rerunner plugin
# -------------------------
RERUNNER_DIR="$BASE_DIR/PLUGIN/rerunner_plugin"
echo "Building rerunner plugin..."
cd "$RERUNNER_DIR" || exit
cmake --build build -j6

# -------------------------
# 3) Run mads sink (DEPENDENT ON FILTER)
# -------------------------
echo "Running mads sink..."

if [ "$FILTER_NAME" = "mads_filter_test" ]; then

    run_mads "mads sink build/rerunner.plugin -n rerunner_test" "$RERUNNER_DIR"

elif [ "$FILTER_NAME" = "pose_estimation" ]; then

    run_mads "mads sink build/rerunner.plugin -n rerunner_pose" "$RERUNNER_DIR"

else
    echo "Unknown filter: $FILTER_NAME"
    exit 1
fi

# -------------------------
# 4) Build selected filter plugin
# -------------------------
# Map filter names to correct directory names
if [ "$FILTER_NAME" = "mads_filter_test" ]; then
    FILTER_DIR="$BASE_DIR/PLUGIN/mads_filter_test"
    FILTER_PLUGIN_FILE="my_filter.plugin"

elif [ "$FILTER_NAME" = "pose_estimation" ]; then
    FILTER_DIR="$BASE_DIR/PLUGIN/pose_estimation_plugin"
    FILTER_PLUGIN_FILE="pose_estimation.plugin"

else
    echo "Unknown filter: $FILTER_NAME"
    exit 1
fi

# Check dir exists
if [ ! -d "$FILTER_DIR" ]; then
    echo "ERROR: Filter directory '$FILTER_DIR' does not exist."
    exit 1
fi

echo "Building filter plugin: $FILTER_NAME"
cd "$FILTER_DIR" || exit
cmake --build build -j6

# -------------------------
# 5) Run selected mads filter
# -------------------------
if [ "$FILTER_NAME" = "mads_filter_test" ]; then

    echo "Running mads_filter_test..."
    run_mads "mads filter build/my_filter.plugin" "$FILTER_DIR"

elif [ "$FILTER_NAME" = "pose_estimation" ]; then

    echo "Running pose_estimation..."
    run_mads "mads filter build/pose_estimation.plugin" "$FILTER_DIR"

fi

# -------------------------
# 6) Build replay plugin
# -------------------------
REPLAY_DIR="$BASE_DIR/PLUGIN/replay_plugin"
echo "Building replay plugin..."
cd "$REPLAY_DIR" || exit
cmake --build build -j6

# -------------------------
# 7) Always run encoders + htc
# -------------------------
echo "Running replay source (encoders)..."
run_mads "mads source build/replay.plugin -n encoders" "$REPLAY_DIR"

echo "Running replay source (htc)..."
run_mads "mads source build/replay.plugin -n htc" "$REPLAY_DIR"

# -------------------------
# 8) Extra sources only for pose_estimation
# -------------------------
if [ "$FILTER_NAME" = "pose_estimation" ]; then

    echo "Running replay source (realsense)..."
    run_mads "mads source build/replay.plugin -n realsense" "$REPLAY_DIR"

    echo "Running replay source (imu)..."
    run_mads "mads source build/replay.plugin -n imu" "$REPLAY_DIR"

fi

echo "All commands launched. Check terminals for output."
