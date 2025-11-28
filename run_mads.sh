#!/bin/bash

# =========================
# Cross-platform MADS Pipeline Launcher
# Ensures each mads command runs in its intended directory
# =========================

# Detect OS
OS="$(uname -s)"
echo "Detected OS: $OS"

# -------------------------
# Function to run mads command in background
# -------------------------
run_mads() {
    CMD="$1"
    DIR="$2"  # Directory to run the command in
    case "$OS" in
        Darwin)  # macOS
            # Open new Terminal, cd to DIR, then run CMD
            osascript -e 'tell application "Terminal" to do script "cd '"$DIR"'; '"$CMD"'"'
            ;;
        Linux)
            # Open new terminal, cd to DIR, then run CMD
            gnome-terminal -- bash -c "cd '$DIR'; $CMD; exec bash"
            ;;
        MINGW*|MSYS*|CYGWIN*|Windows_NT)  # Git Bash / Windows
            start cmd /k "cd /d '$DIR' && $CMD"
            ;;
        *)
            echo "Unsupported OS: $OS"
            ;;
    esac
}

# -------------------------
# 1) Start MADS broker
# -------------------------
BROKER_DIR="$HOME"  # Broker can run from home
echo "Starting MADS broker..."
run_mads "mads broker" "$BROKER_DIR"
sleep 3  # wait for broker to initialize

# -------------------------
# 2) Build rerunner plugin
# -------------------------
RERUNNER_DIR="/Users/alberto/MECHATRONIC_ENGINEERING/ROBOTIC_PERCEPTION/PROJECT/PLUGIN/rerunner_plugin"
echo "Building rerunner plugin..."
cd "$RERUNNER_DIR" || exit
cmake --build build -j6

# -------------------------
# 3) Execute mads sink
# -------------------------
echo "Running mads sink..."
run_mads "mads sink build/rerunner.plugin" "$RERUNNER_DIR"

# -------------------------
# 4) Build filter plugin
# -------------------------
FILTER_DIR="/Users/alberto/MECHATRONIC_ENGINEERING/ROBOTIC_PERCEPTION/PROJECT/PLUGIN/mads_filter_test"
echo "Building filter plugin..."
cd "$FILTER_DIR" || exit
cmake --build build -j6

# -------------------------
# 5) Execute mads filter
# -------------------------
echo "Running mads filter..."
run_mads "mads filter build/my_filter.plugin" "$FILTER_DIR"

# -------------------------
# 6) Build replay plugin
# -------------------------
REPLAY_DIR="/Users/alberto/MECHATRONIC_ENGINEERING/ROBOTIC_PERCEPTION/PROJECT/PLUGIN/replay_plugin"
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
