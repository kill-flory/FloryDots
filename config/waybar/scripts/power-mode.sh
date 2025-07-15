#!/bin/bash

current_mode=$(powerprofilesctl get)

case "$current_mode" in
    "power-saver")
        echo '{"text": "", "tooltip": "Power Saver", "class": "power-saver"}'
        ;;
    "balanced")
        echo '{"text": "", "tooltip": "Balanced", "class": "balanced"}'
        ;;
    "performance")
        echo '{"text": "", "tooltip": "Performance", "class": "performance"}'
        ;;
    *)
        echo '{"text": "?", "tooltip": "Unknown"}'
        ;;
esac
