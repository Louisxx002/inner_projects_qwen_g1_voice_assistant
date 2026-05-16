# Project Structure

## Core

- `qwen_server.py`: HTTP server. Loads local Qwen model, generates replies, and creates Edge TTS mp3 files.
- `qwen_ros_node_edg_tts.py`: ROS2 node. Subscribes to `/audio_msg`, calls the Qwen server, converts mp3 to wav, and triggers G1 reply actions.
- `asr_dds_to_ros_bridge.py`: Safe one-way bridge from Unitree DDS `rt/audio_msg` to ROS2 `/audio_msg`.
- `unitree_audio_player.py`: Watches `runtime/tts.wav` and plays it through Unitree DDS audio.
- `project_config.py`: Centralized environment-backed configuration.
- `wav.py`: WAV loading and audio streaming helpers.

## Configuration

- `config/default.env`: Default runtime configuration.
- `requirements.txt`: Python dependencies for the Qwen/TTS node.

## Scripts

- `scripts/run_server.sh`: Start the Qwen HTTP server.
- `scripts/run_asr_bridge.sh`: Start the safe Unitree DDS ASR to ROS2 bridge.
- `scripts/run_full_pipeline.sh`: Start the full voice chain in one command.
- `scripts/stop_full_pipeline.sh`: Stop the full voice chain.
- `scripts/run_ros_node.sh`: Start the ROS2 text-to-reply node.
- `scripts/run_audio_player.sh`: Start Unitree audio playback.
- `scripts/monitor_audio_msg.sh`: Watch incoming ASR text on `/audio_msg`.
- `scripts/monitor_ros_logs.sh`: Watch ROS node logs.
- `scripts/check_project.sh`: Fast syntax/config check.
- `scripts/check_full_pipeline.sh`: Broader local pipeline check.

## Runtime

- `runtime/`: Generated mp3/wav files and ROS logs. Contents are disposable.
- `runtime/ros_logs/`: ROS log output. Contents are disposable.

## Third Party

- `third_party/unitree_sdk2_python/`: Vendored Unitree SDK2 Python package needed for robot audio/DDS access.
