#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Установка и настройка fail2ban (3 попытки SSH) ===${NC}"

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Ошибка: скрипт нужно запускать с sudo или от root${NC}"
   exit 1
fi

if command -v apt &> /dev/null; then
    echo -e "${YELLOW}Установка fail2ban через apt...${NC}"
    apt update -qq && apt install fail2ban -y -qq
elif command -v yum &> /dev/null; then
    echo -e "${YELLOW}Установка fail2ban через yum (EPEL)...${NC}"
    yum install epel-release -y -q && yum install fail2ban -y -q
elif command -v dnf &> /dev/null; then
    echo -e "${YELLOW}Установка fail2ban через dnf (EPEL)...${NC}"
    dnf install epel-release -y -q && dnf install fail2ban -y -q
else
    echo -e "${RED}Не удалось определить пакетный менеджер. Установите fail2ban вручную.${NC}"
    exit 1
fi

echo -e "${YELLOW}Создание конфигурации /etc/fail2ban/jail.local...${NC}"
cat > /etc/fail2ban/jail.local <<EOF
[DEFAULT]
bantime = 600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = ssh
backend = systemd
EOF

echo -e "${YELLOW}Запуск fail2ban...${NC}"
systemctl restart fail2ban
systemctl enable fail2ban --quiet

sleep 2

echo -e "${YELLOW}Проверка статуса SSH jail:${NC}"
fail2ban-client status sshd

echo -e "${YELLOW}Состояние сервиса fail2ban:${NC}"
systemctl is-active fail2ban --quiet && echo -e "${GREEN}Сервис активен${NC}" || echo -e "${RED}Сервис не активен${NC}"

echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}Готово! После 3 неудачных SSH-попыток IP будет забанен на 10 минут.${NC}"
echo -e "${GREEN}Посмотреть забаненные IP: fail2ban-client status sshd${NC}"
