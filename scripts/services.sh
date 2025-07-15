#!/bin/bash
set -e

# Список сервисов для управления
SERVICES=(
    "nvidia-powerd"
    "power-profiles-daemon.service"
    "upower.service"
    "asusd.service"
)

# Функция для выбора действия
show_menu() {
    clear
    echo "===================================="
    echo "  Меню управления сервисами Systemd  "
    echo "===================================="
    echo "1. Включить и запустить все сервисы"
    echo "2. Остановить и отключить все сервисы"
    echo "3. Проверить статус сервисов"
    echo "4. Выборочное управление сервисами"
    echo "5. Выход"
    echo "===================================="
    read -p "Выберите действие (1-5): " choice
    echo

    case $choice in
        1) enable_start_all ;;
        2) disable_stop_all ;;
        3) check_status ;;
        4) selective_control ;;
        5) exit 0 ;;
        *) echo "Неверный выбор. Попробуйте снова."; sleep 1 ;;
    esac
}

# Включить и запустить все сервисы
enable_start_all() {
    for service in "${SERVICES[@]}"; do
        echo "Обработка сервиса: $service"
        systemctl enable "$service" 2>/dev/null || echo "Не удалось включить $service"
        systemctl start "$service" 2>/dev/null || echo "Не удалось запустить $service"
        systemctl status "$service" --no-pager -l | head -n 5
        echo
    done
    read -p "Нажмите Enter для продолжения..."
}

# Остановить и отключить все сервисы
disable_stop_all() {
    for service in "${SERVICES[@]}"; do
        echo "Обработка сервиса: $service"
        systemctl stop "$service" 2>/dev/null || echo "Не удалось остановить $service"
        systemctl disable "$service" 2>/dev/null || echo "Не удалось отключить $service"
        systemctl status "$service" --no-pager -l | head -n 5
        echo
    done
    read -p "Нажмите Enter для продолжения..."
}

# Проверить статус сервисов
check_status() {
    for service in "${SERVICES[@]}"; do
        echo "Статус сервиса: $service"
        systemctl status "$service" --no-pager -l | head -n 7
        echo "------------------------------------"
    done
    read -p "Нажмите Enter для продолжения..."
}

# Выборочное управление сервисами
selective_control() {
    clear
    echo "===================================="
    echo "  Выборочное управление сервисами    "
    echo "===================================="
    
    # Вывод списка сервисов с номерами
    for i in "${!SERVICES[@]}"; do
        echo "$((i+1)). ${SERVICES[$i]}"
    done
    
    echo
    read -p "Выберите сервис (1-${#SERVICES[@]}), или 0 для возврата: " service_choice
    
    # Проверка выбора
    if [[ $service_choice -eq 0 ]]; then
        return
    elif [[ $service_choice -lt 1 || $service_choice -gt ${#SERVICES[@]} ]]; then
        echo "Неверный выбор. Попробуйте снова."
        sleep 1
        selective_control
        return
    fi
    
    selected_service=${SERVICES[$((service_choice-1))]}
    
    # Меню действий для выбранного сервиса
    clear
    echo "Управление сервисом: $selected_service"
    echo "1. Включить и запустить"
    echo "2. Остановить и отключить"
    echo "3. Проверить статус"
    echo "4. Перезапустить"
    echo "5. Вернуться назад"
    
    read -p "Выберите действие (1-5): " action_choice
    
    case $action_choice in
        1)
            systemctl enable "$selected_service" 2>/dev/null || echo "Не удалось включить $selected_service"
            systemctl start "$selected_service" 2>/dev/null || echo "Не удалось запустить $selected_service"
            ;;
        2)
            systemctl stop "$selected_service" 2>/dev/null || echo "Не удалось остановить $selected_service"
            systemctl disable "$selected_service" 2>/dev/null || echo "Не удалось отключить $selected_service"
            ;;
        3)
            systemctl status "$selected_service" --no-pager -l
            ;;
        4)
            systemctl restart "$selected_service" 2>/dev/null || echo "Не удалось перезапустить $selected_service"
            ;;
        5)
            selective_control
            return
            ;;
        *)
            echo "Неверный выбор."
            ;;
    esac
    
    read -p "Нажмите Enter для продолжения..."
    selective_control
}

# Основной цикл
while true; do
    show_menu
done