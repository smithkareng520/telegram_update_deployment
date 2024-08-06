#!/bin/bash

# 定义默认值
DEFAULT_PORT=81
DEFAULT_USERNAME="dearella"
DEFAULT_PASSWORD="KSXJY123456"
DEFAULT_DOMAIN="yourdomain.com"

# 读取用户输入
read -p "请输入Apache端口号 [默认: $DEFAULT_PORT]: " PORT
read -p "请输入用户名 [默认: $DEFAULT_USERNAME]: " USERNAME
read -p "请输入密码 [默认: $DEFAULT_PASSWORD]: " PASSWORD
read -p "请输入您的域名 [默认: $DEFAULT_DOMAIN]: " DOMAIN

# 使用默认值如果用户没有输入
PORT=${PORT:-$DEFAULT_PORT}
USERNAME=${USERNAME:-$DEFAULT_USERNAME}
PASSWORD=${PASSWORD:-$DEFAULT_PASSWORD}
DOMAIN=${DOMAIN:-$DEFAULT_DOMAIN}

# 显示用户输入的配置
echo "配置如下："
echo "Apache端口号: $PORT"
echo "用户名: $USERNAME"
echo "密码: [隐藏]"
echo "域名: $DOMAIN"

# 更新系统
echo "正在更新系统..."
sudo apt update
sudo apt upgrade -y

# 安装Apache和PHP
echo "正在安装Apache和PHP..."
sudo apt install -y apache2 php libapache2-mod-php php-cli php-curl php-zip curl

# 配置防火墙
echo "正在配置防火墙..."
sudo ufw allow $PORT/tcp
sudo ufw enable


# 更新 Apache 配置文件，监听自定义端口
echo "正在更新 Apache 配置文件..."
sudo tee /etc/apache2/ports.conf > /dev/null <<EOL
Listen 80
Listen 443
Listen $PORT
EOL

# 创建虚拟主机配置
echo "正在创建虚拟主机配置..."
sudo tee /etc/apache2/sites-available/telegram_update.conf > /dev/null <<EOL
<VirtualHost *:$PORT>
    ServerAdmin webmaster@$DOMAIN
    DocumentRoot /var/www/html/telegram_update
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined

    <Directory /var/www/html/telegram_update>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOL

# 启用站点配置和所需模块
echo "正在启用站点配置和所需模块..."
sudo a2ensite telegram_update
sudo a2enmod php
sudo a2enmod mpm_prefork
sudo systemctl restart apache2

# 创建安全目录存放敏感信息
echo "正在创建安全目录存放敏感信息..."
sudo mkdir -p /var/private_data
sudo chown -R www-data:www-data /var/private_data
sudo chmod -R 700 /var/private_data

# 移动 auth.txt 文件到安全目录
echo "正在创建 auth.txt 文件..."
sudo tee /var/private_data/auth.txt > /dev/null <<EOL
$USERNAME:$PASSWORD
EOL

# 创建 PHP 文件
echo "正在创建 PHP 文件..."


# 创建下载脚本
echo "正在创建下载脚本..."

# 下载和更新 Telegram 客户端的脚本
echo "正在创建下载和更新脚本..."
sudo tee /var/www/html/telegram_update/check_and_download_telegram.sh > /dev/null <<'EOL'
#!/bin/bash

# 客户端下载 URL 列表
URLS=(
    "https://telegram.org/dl/desktop/win64_portable"
    "https://telegram.org/dl/desktop/mac"
    "https://telegram.org/dl/desktop/linux"
    "https://telegram.org/dl/android/apk"
)

# Destination directory on VPS
DEST_DIR="/var/www/html/telegram_update"
LOG_FILE="$DEST_DIR/download_log.txt"

# 创建或清空日志文件
: > "$LOG_FILE"

# 处理每个 URL
for URL in "${URLS[@]}"; do
    BASE_NAME=$(basename "$URL")
    FILE_NAME="telegram_${BASE_NAME}.zip"
    LAST_MOD_FILE="$DEST_DIR/${BASE_NAME}_last_modified.txt"
    FILE_PATH="$DEST_DIR/$FILE_NAME"

    echo "$(date): Processing $URL" >> "$LOG_FILE"

    # 如果文件不存在，则下载
    if [ ! -f "$FILE_PATH" ]; then
        echo "$(date): $FILE_NAME not found. Downloading initial version..." >> "$LOG_FILE"
        if curl -s -L -o "$FILE_PATH" "$URL"; then
            echo "$(date): Initial download completed successfully for $FILE_NAME." >> "$LOG_FILE"
        else
            echo "$(date): Error occurred while downloading $FILE_NAME." >> "$LOG_FILE"
        fi

        # 获取并保存 Last-Modified 头部
        LAST_MOD=$(curl -s -I "$URL" | grep -i "Last-Modified" | awk -F': ' '{print $2}')
        echo "$LAST_MOD" > "$LAST_MOD_FILE"
    else
        # 获取新的 Last-Modified 头部
        NEW_LAST_MOD=$(curl -s -I "$URL" | grep -i "Last-Modified" | awk -F': ' '{print $2}')

        # 读取之前保存的 Last-Modified 时间
        if [ -f "$LAST_MOD_FILE" ]; then
            OLD_LAST_MOD=$(cat "$LAST_MOD_FILE")
        else
            OLD_LAST_MOD=""
        fi

        # 比较新的和旧的 Last-Modified 时间
        if [ "$NEW_LAST_MOD" != "$OLD_LAST_MOD" ]; then
            echo "$(date): New version detected for $FILE_NAME. Downloading update..." >> "$LOG_FILE"
            if curl -s -L -o "$FILE_PATH" "$URL"; then
                echo "$(date): Download completed successfully for $FILE_NAME." >> "$LOG_FILE"
            else
                echo "$(date): Error occurred while downloading $FILE_NAME." >> "$LOG_FILE"
            fi
            echo "$NEW_LAST_MOD" > "$LAST_MOD_FILE"
        else
            echo "$(date): No update available for $FILE_NAME." >> "$LOG_FILE"
        fi
    fi
done
EOL

# 赋予脚本执行权限
echo "正在设置脚本执行权限..."
sudo chmod +x /var/www/html/telegram_update/check_and_download_telegram.sh


# 运行更新脚本
echo "正在运行更新脚本..."
sudo bash /var/www/html/telegram_update/check_and_download_telegram.sh

# 设置定时任务
echo "正在设置定时任务..."
(crontab -l 2>/dev/null; echo "*/5 * * * * /var/www/html/telegram_update/check_and_download_telegram.sh") | crontab -

# 提供访问链接
echo "设置完成。您可以通过以下链接访问您的应用："
echo "http://$(hostname -I | awk '{print $1}'):$PORT/index.php"