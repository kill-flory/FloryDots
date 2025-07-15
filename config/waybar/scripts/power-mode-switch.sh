#!/bin/bash

current_mode=$(powerprofilesctl get)

case "$current_mode" in
    "power-saver")
        powerprofilesctl set balanced
        ;;
    "balanced")
        powerprofilesctl set performance
        ;;
    "performance")
        powerprofilesctl set power-saver
        ;;
    *)
        powerprofilesctl set balanced
        ;;
esac

pkill -RTMIN+8 waybar  # Отправляем сигнал Waybar для обновления
