#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

install_required() {
    clear
    echo -e "${YELLOW}Установка обязательных зависимостей...${NC}"
    local packages=($(grep -v '^#' required_depnd.txt))
    pacman -S --needed "${packages[@]}" || {
        echo -e "${RED}Ошибка установки обязательных пакетов${NC}"
        return 1
    }
    
    if ! command -v yay &> /dev/null; then
        echo -e "${YELLOW}Сборка и установка yay...${NC}"
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        cd /tmp/yay
        makepkg -si --noconfirm
        cd -
        rm -rf /tmp/yay
    else
        echo -e "${GREEN}yay уже установлен${NC}"
    fi
    read -p "Нажмите Enter для продолжения..."
    clear
}

install_all_packages() {
    clear
    local file=$1
    local title=$2
    local is_aur=$3
    
    echo -e "\n${YELLOW}=== $title ===${NC}"
    echo "Список пакетов для установки:"
    grep -v '^#' "$file" | nl
    
    while true; do
        echo -e "\n1. Установить все пакеты"
        echo "2. Пропустить"
        echo "3. Вернуться в меню"
        read -p "Выберите действие (1-3): " choice
        
        case $choice in
            1)
                echo -e "${GREEN}Начало установки...${NC}"
                if [ "$is_aur" = true ]; then
                    yay -S --noconfirm $(grep -v '^#' "$file") || echo -e "${RED}Ошибка установки некоторых пакетов${NC}"
                else
                   sudo pacman -S --noconfirm $(grep -v '^#' "$file") || echo -e "${RED}Ошибка установки некоторых пакетов${NC}"
                fi
                read -p "Нажмите Enter для продолжения..."
                clear
                return 0
                ;;
            2)
                echo -e "${YELLOW}Пропуск установки${NC}"
                read -p "Нажмите Enter для продолжения..."
                clear
                return 0
                ;;
            3)
                clear
                return 1
                ;;
            *)
                echo -e "${RED}Неверный выбор!${NC}"
                ;;
        esac
    done
}

install_user_packages() {
    clear
    echo -e "\n${YELLOW}=== Персональные пакеты ===${NC}"

    declare -A categories=(
        ["Яндекс музыка"]="yandex-music"
        ["Telegram"]="telegram-desktop"
        ["Zen Browser"]="zen-browser-bin"
        ["Пакеты для монтирования NTFS"]="ntfsfixboot ntfs-3g"
        ["VS Code"]="visual-studio-code-bin"
        ["Flatpak"]="flatpak"
        ["Steam"]="steam"
        ["Шрифты"]="ttf-dejavu ttf-firacode-nerd ttf-font-awesome ttf-hack ttf-opensans"
        ["Графические драйверы Nvidia"]="lib32-libxnvctrl lib32-nvidia-utils nemo-run-with-nvidia-prime-run nvidia nvidia-prime nvidia-settings lib32-vulkan-icd-loader lib32-vulkan-intel mesa-utils vulkan-headers vulkan-intel vulkan-tools nvtop"
        ["Xorg"]="xorg-bdftopcf xorg-docs xorg-font-util xorg-fonts-100dpi xorg-fonts-75dpi xorg-iceauth xorg-mkfontscale xorg-server xorg-server-devel xorg-server-xephyr xorg-server-xnest xorg-server-xvfb xorg-sessreg xorg-smproxy xorg-x11perf xorg-xauth xorg-xbacklight xorg-xcmsdb xorg-xcursorgen xorg-xdpyinfo xorg-xdriinfo xorg-xev xorg-xgamma xorg-xhost xorg-xinput xorg-xkbevd xorg-xkbutils xorg-xkill xorg-xlsatoms xorg-xlsclients xorg-xmodmap xorg-xpr xorg-xrandr xorg-xrefresh xorg-xsetroot xorg-xvinfo xorg-xwd xorg-xwininfo xorg-xwud"
    )

    while true; do
        clear
        echo -e "\n${YELLOW}Доступные категории:${NC}"
        local i=1
        local category_names=()
        for category in "${!categories[@]}"; do
            echo "$i. $category"
            category_names[$i]="$category"
            ((i++))
        done
        echo "$i. Вернуться в меню"
        
        read -p "Выберите категорию (1-$i): " category_choice
        
        if [[ $category_choice -eq $i ]]; then
            clear
            return 0
        fi
        
        if [[ $category_choice -lt 1 ]] || [[ $category_choice -ge $i ]]; then
            echo -e "${RED}Неверный выбор!${NC}"
            sleep 1
            continue
        fi
        
        selected_category="${category_names[$category_choice]}"
        packages=(${categories[$selected_category]})
        
        while true; do
            clear
            echo -e "\n${GREEN}Выбрана категория: $selected_category${NC}"
            echo "Пакеты: ${packages[*]}"
            
            echo -e "\n1. Установить все пакеты категории"
            echo "2. Пропустить категорию"
            echo "3. Вернуться к выбору категории"
            read -p "Выберите действие (1-3): " action_choice
            
            case $action_choice in
                1)
                    if [[ "$selected_category" == "Zen Browser" ]] || 
                       [[ "$selected_category" == "Яндекс музыка" ]] || 
                       [[ "$selected_category" == "Telegram" ]] || 
                       [[ "$selected_category" == "Пакеты для монтирования NTFS" ]] || 
                       [[ "$selected_category" == "Flatpak" ]] || 
                       [[ "$selected_category" == "Шрифты" ]] || 
                       [[ "$selected_category" == "Steam" ]] || 
                       [[ "$selected_category" == "Графические драйверы Nvidia" ]] || 
                       [[ "$selected_category" == "Xorg" ]] || 
                       [[ "$selected_category" == "VS Code" ]]; then
                        manager="yay"
                    else
                        manager="pacman"
                    fi
                    
                    echo -e "${YELLOW}Установка пакетов через $manager...${NC}"
                    if [[ "$manager" == "yay" ]]; then
                        yay -S --noconfirm "${packages[@]}" || echo -e "${RED}Ошибка установки некоторых пакетов${NC}"
                    else
                        sudo pacman -S --noconfirm "${packages[@]}" || echo -e "${RED}Ошибка установки некоторых пакетов${NC}"
                    fi
                    read -p "Нажмите Enter для продолжения..."
                    break
                    ;;
                2)
                    echo -e "${YELLOW}Пропуск категории $selected_category${NC}"
                    read -p "Нажмите Enter для продолжения..."
                    break
                    ;;
                3)
                    break
                    ;;
                *)
                    echo -e "${RED}Неверный выбор!${NC}"
                    sleep 1
                    ;;
            esac
        done
    done
    
    return 0
}

# Главное меню
main_menu() {
    while true; do
        clear
        echo -e "\n${YELLOW}=== Главное меню ===${NC}"
        echo "1. Установить обязательные зависимости и yay"
        echo "2. Установить пакеты для Hyprland"
        echo "3. Установить пакеты для адекватной работы"
        echo "4. Установить персональные пакеты (опционально)"
        echo "5. Завершить установку"
        read -p "Выберите действие (1-5): " main_choice
        
        cd ..
        cd Pakage

        case $main_choice in
            1)
                install_required
                ;;
            2)
                install_all_packages "hypr_list.txt" "Пакеты для Hyprland" false
                ;;
            3)
                install_all_packages "pkg_list.txt" "Пакеты для адекватной работы" true
                ;;
            4)
                install_user_packages
                ;;
            5)
                clear
                echo -e "${GREEN}Установка завершена!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Неверный выбор!${NC}"
                sleep 1
                ;;
        esac
    done
}

main_menu