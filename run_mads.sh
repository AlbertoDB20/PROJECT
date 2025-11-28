#!/bin/bash

# 1) Start mads broker
echo "Starting mads broker..."
mads broker

# 2) Navigate to rerunner_plugin directory
cd /Users/alberto/MECHATRONIC_ENGINEERING/ROBOTIC_PERCEPTION/PROJECT/PLUGIN/rerunner_plugin

# 3) Build rerunner plugin
cmake --build build -j6

# 4) Execute mads sink
mads sink build/rerunner.plugin

# 5) Navigate to mads_filter_test directory
cd "/Users/alberto/MECHATRONIC_ENGINEERING/ROBOTIC_PERCEPTION/PROJECT/PLUGIN/mads_filter_test"

# 6) Build filter plugin
cmake --build build -j6

# 7) Execute mads filter
mads filter build/my_filter.plugin

# 8) Navigate to replay_plugin directory
cd "/Users/alberto/MECHATRONIC_ENGINEERING/ROBOTIC_PERCEPTION/PROJECT/PLUGIN/replay_plugin"

# 9) Build replay plugin
cmake --build build -j6

# 10) Replay source (encoders)
mads source build/replay.plugin -n encoders

# 11) Replay source (htc)
mads source build/replay.plugin -n htc
