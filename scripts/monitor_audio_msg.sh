#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
set -a
source "${PROJECT_ROOT}/config/default.env"
set +a

set +u
source "${ROS_SETUP:-/opt/ros/${ROS_DISTRO:-jazzy}/setup.bash}"
set -u

echo "Monitoring /audio_msg. Press Ctrl+C to stop."
ros2 topic echo /audio_msg
