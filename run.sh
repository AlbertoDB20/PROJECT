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
    echo "Usage: ./run.sh <filter_directory_name>"
    echo "Example: ./run.sh mads_filter_test"
    echo "         ./run.sh pose_estimation_plugin"
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

# Base directory of the script
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

# -------------------------
# 1) Start MADS broker
# -------------------------
BROKER_DIR="$BASE_DIR"
echo "Starting MADS broker..."
run_mads "mads broker" "$BROKER_DIR"
sleep 3

# -------------------------
# 2) Build rerunner plugin
# -------------------------
RERUNNER_DIR="$BASE_DIR/PLUGIN/rerunner_plugin"
echo "Building rerunner plugin..."
cd "$RERUNNER_DIR" || exit
cmake --build build -j6

# -------------------------
# 3) Execute mads sink
# -------------------------
echo "Running mads sink..."
run_mads "mads sink build/rerunner.plugin" "$RERUNNER_DIR"

# -------------------------
# 4) Build selected filter plugin
# -------------------------
FILTER_DIR="$BASE_DIR/PLUGIN/$FILTER_NAME"
PLUGIN_FILE=$(ls "$FILTER_DIR/build/"*.plugin 2>/dev/null | head -n1)

if [ ! -d "$FILTER_DIR" ]; then
    echo "ERROR: Filter '$FILTER_NAME' does not exist in PLUGIN/"
    exit 1
fi

echo "Building filter plugin: $FILTER_NAME"
cd "$FILTER_DIR" || exit
cmake --build build -j6

# -------------------------
# 5) Execute mads filter
# -------------------------
echo "Running mads filter: $FILTER_NAME ..."
run_mads "mads filter $PLUGIN_FILE" "$FILTER_DIR"

# -------------------------
# 6) Build replay plugin
# -------------------------
REPLAY_DIR="$BASE_DIR/PLUGIN/replay_plugin"
echo "Building replay plugin..."
cd "$REPLAY_DIR" || exit
cmake --build build -j6

# -------------------------
# 7) Replay sources
# -------------------------
echo "Running replay source (encoders)..."
run_mads "mads source build/replay.plugin -n encoders" "$REPLAY_DIR"

echo "Running replay source (htc)..."
run_mads "mads source build/replay.plugin -n htc" "$REPLAY_DIR"

echo "All commands launched. Check terminals for output."
