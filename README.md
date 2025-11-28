# MADS Plugin Pipeline

This project contains a set of plugins developed for the **MADS** platform, used in robotic perception applications.  
The main goal is to automate the process of:

- building the plugins  
- running the *sink*, *filter*, and *source* components  
- replaying sensor data via the replay plugin  

All of this is orchestrated through a Bash script that allows launching the entire pipeline with a single command.

---

## Project Structure

The `PROJECT/PLUGIN/` folder contains multiple modules, each serving a specific role within the MADS system:

- **rerunner_plugin/** → handles rerunning of saved data  
- **mads_filter_test/** → contains the filter plugin (test)
- **replay_plugin/** → responsible for replaying data sequences  

Each module includes its own `CMakeLists.txt` and a dedicated `build/` folder.

---

## Automation Script

The following script:

- starts the MADS broker  
- builds each plugin using CMake  
- runs the *sink*, *filter*, and *source* in the correct order  
- replays data such as "encoders" and "htc" through the replay plugin  

### `run.sh`
```bash
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

```

## How to Run

Make the script executable:
```bash
chmod +x run.sh
```

Then launch the pipeline:
```bash
./run.sh
```

Notes:
- The directory paths are currently configured for macOS.
- For Linux or Windows, the paths in the script must be adapted.
- Plugins expect the `build/` directories to exist and be configured via CMake.