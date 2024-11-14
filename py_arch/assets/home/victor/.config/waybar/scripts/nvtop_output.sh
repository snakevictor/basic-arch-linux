#!/bin/bash

# Query the GPU temperature and usage from nvidia-smi
TEMP=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits)
USAGE=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits)

# Format the output for Waybar
echo "${USAGE}%     ${TEMP}°C"
