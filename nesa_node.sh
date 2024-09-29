#!/bin/bash

tput reset
tput civis

# Put your logo here if nessesary

show_orange() {
    echo -e "\e[33m$1\e[0m"
}

show_blue() {
    echo -e "\e[34m$1\e[0m"
}

show_green() {
    echo -e "\e[32m$1\e[0m"
}

show_red() {
    echo -e "\e[31m$1\e[0m"
}

find_and_print() {
    local file=$1
    local key=$2

    local value=$(grep "^$key" "$file" | cut -d '=' -f 2-)

    if [ -n "$value" ]; then
        show_orange "$key$value"
    else
        show_red "$key не найдено (not found)"
    fi
}

show_orange "   \ |  __|   __|    \       \ |   _ \   _ \   __| "
show_orange "  .  |  _|  \__ \   _ \     .  |  (   |  |  |  _| "
show_orange " _|\_| ___| ____/ _/  _\   _|\_| \___/  ___/  ___| "
echo ""
sleep 2

while true; do
    echo "1. Подготовка к установке Nesa (Preparation)"
    echo "2. Установить/Изменить/Восстaновить Nesa (Installation/Modify/Restore)"
    echo "3. Проверить контейнеры (Check containers)"
    echo "4. О ноде (About node)"
    echo "5. Удалить ноду (Delete node)"
    echo "6. Выход (Exit)"
    echo ""
    read -p "Выберите опцию (Select option): " option

    case $option in
        1)
            # Preparation to install
            show_orange "Начинаем подготовку (Starting preparation)..."
            sleep 1
            # Update and install packages
            cd $HOME
            show_orange "Обновляем и устанавливаем пакеты (Updating and installing packages)..."
            if sudo apt update && sudo apt upgrade -y && sudo apt install -y curl sed git jq gum lz4 build-essential screen nano unzip mc; then
                sleep 1
                echo ""
                show_green "Успешно (Success)"
                echo ""
            else
                sleep 1
                echo ""
                show_red "Ошибка (Fail)"
                echo ""
            fi

            # ADD GPG Key and REP
            show_orange "Добавление GPG ключа и репозитория Docker (ADD GPG Key and REP)..."
            sleep 1

            if sudo apt-get update && \
            sudo apt-get install -y ca-certificates curl && \
            sudo install -m 0755 -d /etc/apt/keyrings && \
            sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc && \
            sudo chmod a+r /etc/apt/keyrings/docker.asc; then
                sleep 1
                echo ""
                show_green "Успешно (Success)"
                echo ""
            else
                sleep 1
                echo ""
                show_red "Ошибка (Fail)"
                echo ""
            fi

            # Add rep in APT
            show_orange "Добавление репозитория Docker (Add docker rep)..."
            sleep 1
            if echo \
                "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
                $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
                sudo tee /etc/apt/sources.list.d/docker.list > /dev/null; then
                sleep 1
                echo ""
                show_green "Успешно (Success)"
                echo ""
            else
                sleep 1
                echo ""
                show_red "Ошибка (Fail)"
                echo ""
            fi

            sudo apt-get update

            # Check if docker installed
            show_orange "Ищем Docker (Looking for docker)..."
            echo ""
            sleep 1
            if ! command -v docker &> /dev/null; then
                show_orange "Установка (Installing)..."
                sleep 1
                sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
                show_green "--- Установлен (Installed) ---"
            else
                show_orange "Обновляем (Updating)..."
                sudo apt-get install --only-upgrade -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
                show_green "--- Обновлен (Updated). ---"
            fi
            echo ""
            show_green "--- ПОДГОТОВКА ЗАВЕРШЕНА. PREPARATION COMPLETED ---"
            echo ""
            ;;
        2)
            # installation Nesa
            show_orange "Начинаем установку (Starting installation)..."
            echo ""
            sleep 2
            bash <(curl -s https://raw.githubusercontent.com/nesaorg/bootstrap/master/bootstrap.sh)
            echo ""
            ;;
        3)
            # check node status
            echo ""
            docker ps -a
            echo ""
            ;;
        4)
            # get node info
            show_orange "Получаем данные Nesa (Getting Nesa data)..."
            sleep 2

            BASE_ENV="$HOME/.nesa/env/base.env"
            ORCHESTRATOR_ENV="$HOME/.nesa/env/orchestrator.env"
            IDENTITY="$HOME/.nesa/identity/node_id.id"
            AGENT_ENV="$HOME/.nesa/env/agent.env"

            show_blue "----- NODE DATA -----"
            echo ""
            find_and_print "$BASE_ENV" "MONIKER="
            find_and_print "$BASE_ENV" "OP_EMAIL="
            find_and_print "$BASE_ENV" "REF_CODE="
            find_and_print "$BASE_ENV" "PUBLIC_IP="
            find_and_print "$ORCHESTRATOR_ENV" "HUGGINGFACE_API_KEY="
            find_and_print "$ORCHESTRATOR_ENV" "NESA_NODE_TYPE="
            find_and_print "$ORCHESTRATOR_ENV" "NODE_PRIV_KEY="
            find_and_print "$AGENT_ENV" "CHAIN_ID="
            show_orange "NODE_ID=$(cat $IDENTITY)"

            echo ""
            show_blue "----- NODE DATA -----"
            echo ""
            ;;
        5)
            # deleting node
            show_orange "Удаляем ноду (Deletting node)..."
            echo ""
            sleep 2
            show_orange "Останавливаем контейнеры (Stopping containers)..."
            if docker stop orchestrator docker-watchtower-1 mongodb ipfs_node; then
                sleep 1
                show_green "Успешно (Success)"
                echo ""
            else
                sleep 1
                show_blue "Нода не запущена (Node is not running)"
                echo ""
            fi

            show_orange "Удаляем контейнеры (Deleting containers)..."
            if docker rm orchestrator docker-watchtower-1 mongodb ipfs_node; then
                sleep 1
                show_green "Успешно (Success)"
                echo ""
            else
                sleep 1
                show_blue "Не найдены (NOT FOUND)"
                echo ""
            fi

            show_orange "Удаляем файлы (Deleting files)..."
            if rm -rvf $HOME/.nesa; then
                sleep 1
                show_green "Успешно (Success)"
                echo ""
            else
                sleep 1
                show_red "Ошибка (Fail)"
                echo ""
            fi
            show_green "----- НОДА УДАЛЕНА. NODE DELETED -----"
            echo ""
            ;;
        6)
            # Stop script and exit
            show_red "Скрипт остановлен (Script stopped)"
            echo ""
            exit 0
            ;;
        *)
            # incorrect options handling
            echo ""
            echo -e "\e[31mНеверная опция\e[0m. Пожалуйста, выберите из тех, что есть."
            echo ""
            echo -e "\e[31mInvalid option.\e[0m Please choose from the available options."
            echo ""
            ;;
    esac
done
