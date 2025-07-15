#!/bin/bash

#if [ "$(id -u)" -ne 0 ]; then
#    echo "Этот скрипт требует root-прав."
#    exit 1
#fi

if ! groups $USER | grep -q '\busers\b'; then
    echo "❌ ОШИБКА: Пользователь $USER не в группе 'users'!"
    echo "Выполните следующие команды:"
    echo "1. Добавить в группу: sudo usermod -aG users $USER"
    echo "2. Перезагрузиться: reboot"
    echo "3. Запустить скрипт снова"
    exit 1
fi

ask_choice() {
    local prompt="$1"
    echo "$prompt"
    select choice in "Установить" "Продолжить без установки" "Выйти из скрипта"; do
        case $choice in
            "Установить") return 0 ;;
            "Продолжить без установки") return 1 ;;
            "Выйти из скрипта") exit 1 ;;
            *) echo "Неверный выбор, попробуйте снова"; continue ;;
        esac
    done
}

if ask_choice "Установить базовые пакеты (base-devel, git, cmake и др.)?"; then
    echo "Установка необходимых пакетов..."
    pacman -S --needed base base-devel git cmake pkg-config libpciaccess rust udev boost gtk3 glib2 seatd || {
        echo "Ошибка установки базовых пакетов"
        ask_choice "Продолжить несмотря на ошибку?" || exit 1
    }
fi

if ask_choice "Выполнить полное обновление системы (pacman -Syu)?"; then
    echo "Обновление системы..."
    pacman -Syu || {
        echo "Ошибка обновления системы"
        ask_choice "Продолжить несмотря на ошибку?" || exit 1
    }
fi

# Установка драйверов NVIDIA
if ask_choice "Установить проприетарные драйверы NVIDIA?"; then
    echo "Установка драйверов NVIDIA..."
    pacman -S --needed nvidia nvidia-utils nvidia-settings || {
        echo "Ошибка установки драйверов NVIDIA"
        ask_choice "Продолжить без драйверов NVIDIA?" || exit 1
    }
fi

# Настройка seatd
if ask_choice "Включить и запустить службу seatd?"; then
    systemctl enable --now seatd
    systemctl status seatd || {
        echo "Ошибка запуска seatd"
        ask_choice "Продолжить без работающего seatd?" || exit 1
    }
fi

# Настройка PKG_CONFIG_PATH
echo "Поиск libseat.pc..."
LIBSEAT_PATH=$(find /usr -name libseat.pc 2>/dev/null | head -n 1)

if [ -z "$LIBSEAT_PATH" ]; then
    echo "❌ Файл libseat.pc не найден!"
    if ask_choice "Установить libseat и повторить поиск?"; then
        pacman -S libseat
        LIBSEAT_PATH=$(find /usr -name libseat.pc 2>/dev/null | head -n 1)
    fi
    
    if [ -z "$LIBSEAT_PATH" ]; then
        echo "Ручное решение:"
        echo "1. Найдите путь: find /usr -name libseat.pc"
        echo "2. Экспортируйте: export PKG_CONFIG_PATH=/путь/к/libseat.pc"
        ask_choice "Продолжить без настройки PKG_CONFIG_PATH?" || exit 1
    fi
fi

if [ -n "$LIBSEAT_PATH" ]; then
    PKG_CONFIG_DIR=$(dirname "$LIBSEAT_PATH")
    echo "Настройка PKG_CONFIG_PATH: $PKG_CONFIG_DIR"
    export PKG_CONFIG_PATH="$PKG_CONFIG_DIR:$PKG_CONFIG_PATH"
    echo "PKG_CONFIG_PATH установлен в: $PKG_CONFIG_PATH"
fi

# Установка supergfxctl
if ask_choice "Установить supergfxctl?"; then
    echo "Создание рабочей директории..."
    mkdir -p ~/Asus
    cd ~/Asus
    
    if [ -d "supergfxctl" ]; then
        echo "Директория supergfxctl уже существует, обновление..."
        cd supergfxctl
    else
        git clone https://gitlab.com/asus-linux/supergfxctl.git
        cd supergfxctl
    fi
    
    make && sudo make install || {
        echo "Ошибка установки supergfxctl"
        ask_choice "Продолжить без supergfxctl?" || exit 1
    }
    
    echo "Настройка службы supergfxd..."
    systemctl enable --now supergfxd
    systemctl status supergfxd || {
        echo "Ошибка запуска supergfxd"
        journalctl -xe
        ask_choice "Продолжить без работающего supergfxd?" || exit 1
    }
fi

# Установка asusctl
if ask_choice "Установить asusctl?"; then
    cd ~/Asus
    if [ -d "asusctl" ]; then
        echo "Директория asusctl уже существует, обновление..."
        cd asusctl
    else
        git clone https://gitlab.com/asus-linux/asusctl.git
        cd asusctl
    fi
    
    make && sudo make install || {
        echo "Ошибка установки asusctl"
        ask_choice "Продолжить без asusctl?" || exit 1
    }
fi

# Настройка udev правил
if ask_choice "Настроить udev правила для NVIDIA GPU?"; then
    echo "Поиск NVIDIA GPU..."
    GPU_INFO=$(lspci -nn | grep -i "nvidia.*vga\|3d\|display")
    
    if [ -n "$GPU_INFO" ]; then
        VENDOR_DEVICE=$(echo "$GPU_INFO" | grep -oP '\[[\da-f]+:[\da-f]+\]' | tr -d '[]')
        VENDOR_ID="0x${VENDOR_DEVICE%%:*}"
        DEVICE_ID="0x${VENDOR_DEVICE##*:}"
        
        echo "Найдена NVIDIA GPU:"
        echo "Vendor ID: $VENDOR_ID"
        echo "Device ID: $DEVICE_ID"
        
        UDEV_RULE_FILE="/etc/udev/rules.d/99-supergfxctl.rules"
        echo "Создание udev правила в $UDEV_RULE_FILE..."
        
        cat > "$UDEV_RULE_FILE" << EOF
# Правило для NVIDIA GPU
SUBSYSTEM=="pci", ATTRS{vendor}=="$VENDOR_ID", ATTRS{device}=="$DEVICE_ID", MODE="0666"
EOF
        
        udevadm control --reload-rules
        udevadm trigger
    else
        echo "NVIDIA GPU не найдена!"
        ask_choice "Продолжить без настройки правил udev?" || exit 1
    fi
fi

# Настройка гибридного режима
if ask_choice "Настроить гибридный режим графики?"; then
    supergfxctl -m hybrid || {
        echo "Ошибка настройки режима графики"
        ask_choice "Продолжить без настройки режима?" || exit 1
    }
fi

echo -e "\nУстановка завершена! "
echo "Проверьте:"
echo "1. Статус служб: systemctl status supergfxd seatd"
echo "2. Режим графики: supergfxctl -g"
echo "3. Доступные функции: asusctl --help"

exit 0