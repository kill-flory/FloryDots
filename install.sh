#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

#if ! sudo -n true 2>/dev/null; then
#  echo "Запустите скрипт с sudo."
#  exit 1
#fi

ask_yesno() {
  while true; do
    read -p "$1 (y/n): " answer
    case $answer in
      [Yy]* ) return 0;;
      [Nn]* ) return 1;;
      * ) echo "Пожалуйста, введите y или n.";;
    esac
  done
}

echo ""
if ! grep -q '^\[multilib\]' /etc/pacman.conf; then
  echo "Включение репозитория multilib..."
  echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" | sudo tee -a /etc/pacman.conf
  sudo pacman -Syu
else
  echo "Репозиторий multilib уже включен."
  sleep 1
fi

if [ ! -f "/usr/bin/yay" ]; then
  echo ""
  echo "Установка yay..."
  sudo pacman -Syu --needed base-devel git
  git clone "https://aur.archlinux.org/yay.git" "$HOME/.yay"
  cd "$HOME/.yay"
  makepkg -si
  cd ..
  rm -rf "$HOME/.yay"
fi

# Исправленная строка для установки прав на скрипты
if [ -d "$SCRIPT_DIR/scripts" ]; then
  chmod +x "$SCRIPT_DIR"/scripts/*.sh
else
  echo "Директория со скриптами не найдена: $SCRIPT_DIR/scripts/"
  exit 1
fi

echo ""
echo "Запуск скриптов установки..."

SCRIPTS_DIR="$SCRIPT_DIR/scripts"
SCRIPTS=("pakage.sh" "Hybrid_Nvidia.sh" "services.sh")

for script in "${SCRIPTS[@]}"; do
  script_path="$SCRIPTS_DIR/$script"
  if [ -f "$script_path" ]; then
    if ask_yesno "Запустить скрипт $script?"; then
      echo "Запуск $script..."
      sudo bash "$script_path"
    else
      echo "Пропуск $script"
    fi
  else
    echo "Скрипт $script не найден в $SCRIPTS_DIR"
  fi
  clear
done

if ask_yesno "Хотите установить dotfiles (конфигурационные файлы)?"; then
  echo ""
  echo "Копирование dotfiles..."
  sleep 1
  
  [ ! -d "$HOME/.config" ] && mkdir -p "$HOME/.config"
  [ ! -d "$HOME/.themes" ] && mkdir -p "$HOME/.themes"
  [ ! -d "$HOME/wallpaper" ] && mkdir -p "$HOME/wallpaper"

  if [ -d "$SCRIPT_DIR/config" ]; then
    if ask_yesno "Установить конфиги из $SCRIPT_DIR/config в $HOME/.config?"; then 
      cp -rv "$SCRIPT_DIR/config/." "$HOME/.config/"
      #sudo chown -R "$CURRENT_USER":"$CURRENT_USER" "$HOME/.config"
    fi
    clear
  fi

  if [ -d "$SCRIPT_DIR/themes" ]; then
    if ask_yesno "Установить темы из $SCRIPT_DIR/themes в $HOME/.themes?"; then
      cp -rv "$SCRIPT_DIR/themes/." "$HOME/.themes/"
      #sudo chown -R "$CURRENT_USER":"$CURRENT_USER" "$HOME/.themes"
    fi
  fi

  if [ -d "$SCRIPT_DIR/wallpaper" ]; then
    if ask_yesno "Установить обои из $SCRIPT_DIR/wallpaper в $HOME/wallpaper?"; then
      cp -rv "$SCRIPT_DIR/wallpaper/." "$HOME/wallpaper/"
      #sudo chown -R "$CURRENT_USER":"$CURRENT_USER" "$HOME/wallpaper"
    fi
  fi
else
  echo "Пропуск установки dotfiles."
fi

echo ""
echo "Установка завершена!"
if ask_yesno "Хотите выполнить перезагрузку сейчас?"; then
  echo "Перезагрузка через 5 секунд..."
  sleep 5
  sudo reboot
fi