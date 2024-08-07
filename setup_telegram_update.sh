#!/bin/bash

# 定义默认值
DEFAULT_PORT=81
DEFAULT_MT_PROTO_PORT=442
DEFAULT_USERNAME="admin"
DEFAULT_PASSWORD="admin"
DEFAULT_DOMAIN="yourdomain.com"

# 读取用户输入
read -p "请输入Apache端口号 [默认: $DEFAULT_PORT]: " PORT
read -p "请输入MTProto代理端口号 [默认: $DEFAULT_MT_PROTO_PORT]: " MT_PROTO_PORT
read -p "请输入用户名 [默认: $DEFAULT_USERNAME]: " USERNAME
read -sp "请输入密码 [默认: $DEFAULT_PASSWORD]: " PASSWORD
echo
read -p "请输入您的域名 [默认: $DEFAULT_DOMAIN]: " DOMAIN

# 使用默认值如果用户没有输入
PORT=${PORT:-$DEFAULT_PORT}
MT_PROTO_PORT=${MT_PROTO_PORT:-$DEFAULT_MT_PROTO_PORT}
USERNAME=${USERNAME:-$DEFAULT_USERNAME}
PASSWORD=${PASSWORD:-$DEFAULT_PASSWORD}
DOMAIN=${DOMAIN:-$DEFAULT_DOMAIN}

# 显示用户输入的配置
echo "配置如下："
echo "Apache端口号: $PORT"
echo "MTProto代理端口号: $MT_PROTO_PORT"
echo "用户名: $USERNAME"
echo "密码: [隐藏]"
echo "域名: $DOMAIN"

# 系统识别和更新
echo "正在识别操作系统..."
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_NAME=$ID
    OS_VERSION=$VERSION_ID
else
    echo "无法识别操作系统。"
    exit 1
fi

echo "操作系统: $OS_NAME $OS_VERSION"

# 安装 Docker
install_docker() {
    if command -v docker > /dev/null 2>&1; then
        echo "Docker 已经安装。"
        return
    fi

    echo "正在安装 Docker..."
    case "$OS_NAME" in
        centos)
            sudo yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine
            sudo yum install -y yum-utils
            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            sudo systemctl start docker
            ;;
        debian|ubuntu)
            sudo apt-get remove -y docker.io docker-doc docker-compose podman-docker containerd runc
            sudo apt-get update
            sudo apt-get install -y ca-certificates curl
            sudo install -m 0755 -d /etc/apt/keyrings
            sudo curl -fsSL https://download.docker.com/linux/$(lsb_release -c | awk '{print $2}')/gpg -o /etc/apt/keyrings/docker.asc
            sudo chmod a+r /etc/apt/keyrings/docker.asc
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/$(lsb_release -c | awk '{print $2}') stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        rhel)
            sudo yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine podman runc
            sudo yum install -y yum-utils
            sudo yum-config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
            sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            sudo systemctl start docker
            ;;
        fedora)
            sudo dnf remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-selinux docker-engine-selinux docker-engine
            sudo dnf -y install dnf-plugins-core
            sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
            sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            sudo systemctl start docker
            ;;
        *)
            echo "不支持的操作系统。"
            exit 1
            ;;
    esac
    sudo docker run hello-world
}

# 调用安装 Docker 的函数
install_docker

# 安装 Apache 和 PHP
echo "正在安装 Apache 和 PHP..."
case "$OS_NAME" in
    ubuntu|debian)
        sudo apt-get install -y apache2 php libapache2-mod-php php-cli php-curl php-zip curl
        ;;
    centos|rhel)
        sudo yum install -y httpd php php-cli php-curl php-zip curl
        sudo systemctl start httpd
        sudo systemctl enable httpd
        ;;
    fedora)
        sudo dnf install -y httpd php php-cli php-curl php-zip curl
        sudo systemctl start httpd
        sudo systemctl enable httpd
        ;;
esac

# 配置防火墙
echo "正在配置防火墙..."
case "$OS_NAME" in
    ubuntu|debian)
        sudo ufw allow $PORT/tcp
        sudo ufw allow $MT_PROTO_PORT/tcp
        sudo ufw --force enable
        ;;
    centos|rhel|fedora)
        sudo firewall-cmd --permanent --add-port=$PORT/tcp
        sudo firewall-cmd --permanent --add-port=$MT_PROTO_PORT/tcp
        sudo firewall-cmd --reload
        ;;
esac

# 更新 Apache 配置文件
update_apache_config() {
    case "$OS_NAME" in
        ubuntu|debian)
            if ! grep -q "Listen $PORT" /etc/apache2/ports.conf; then
                echo "Listen $PORT" | sudo tee -a /etc/apache2/ports.conf
            fi
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
            ;;
        centos|rhel|fedora)
            if ! grep -q "Listen $PORT" /etc/httpd/conf/httpd.conf; then
                echo "Listen $PORT" | sudo tee -a /etc/httpd/conf/httpd.conf
            fi
            sudo tee /etc/httpd/conf.d/telegram_update.conf > /dev/null <<EOL
<VirtualHost *:$PORT>
    ServerAdmin webmaster@$DOMAIN
    DocumentRoot /var/www/html/telegram_update
    ErrorLog logs/error_log
    CustomLog logs/access_log combined

    <Directory /var/www/html/telegram_update>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOL
            sudo systemctl restart httpd
            ;;
    esac
}

# 调用更新 Apache 配置文件的函数
update_apache_config

# 创建安全目录存放敏感信息
echo "正在创建安全目录存放敏感信息..."
sudo mkdir -p /var/private_data
sudo chown -R www-data:www-data /var/private_data
sudo chmod -R 700 /var/private_data

# 创建 auth.txt 文件
echo "正在创建 auth.txt 文件..."
sudo tee /var/private_data/auth.txt > /dev/null <<EOL
$USERNAME:$PASSWORD
EOL

# 创建和配置下载脚本
echo "正在创建 check_and_download_telegram.sh 脚本..."
sudo mkdir -p /var/www/html/telegram_update
sudo tee /var/www/html/telegram_update/check_and_download_telegram.sh > /dev/null <<EOL
#!/bin/bash

# 客户端下载 URL 列表
URLS=(
    "https://telegram.org/dl/desktop/win64_portable"
    "https://telegram.org/dl/desktop/mac"
    "https://telegram.org/dl/desktop/linux"
    "https://telegram.org/dl/android/apk"
)

# 目标目录
DEST_DIR="/var/www/html/telegram_update"
LOG_FILE="\$DEST_DIR/download_log.txt"

# 创建或清空日志文件
: > "\$LOG_FILE"

# 处理每个 URL
for URL in "\${URLS[@]}"; do
    BASE_NAME=\$(basename "\$URL")
    FILE_NAME="telegram_\${BASE_NAME}.zip"
    LAST_MOD_FILE="\$DEST_DIR/\${BASE_NAME}_last_modified.txt"
    FILE_PATH="\$DEST_DIR/\$FILE_NAME"

    echo "\$(date): Processing \$URL" >> "\$LOG_FILE"

    # 如果文件不存在，则下载
    if [ ! -f "\$FILE_PATH" ]; then
        echo "\$(date): \$FILE_NAME not found. Downloading initial version..." >> "\$LOG_FILE"
        if curl -s -L -o "\$FILE_PATH" "\$URL"; then
            echo "\$(date): Downloaded \$FILE_NAME successfully." >> "\$LOG_FILE"
        else
            echo "\$(date): Error occurred while downloading \$FILE_NAME." >> "\$LOG_FILE"
        fi

        # 获取并保存 Last-Modified 头部
        LAST_MOD=\$(curl -s -I "\$URL" | grep -i "Last-Modified" | awk -F': ' '{print \$2}')
        echo "\$LAST_MOD" > "\$LAST_MOD_FILE"
    else
        # 获取新的 Last-Modified 头部
        NEW_LAST_MOD=\$(curl -s -I "\$URL" | grep -i "Last-Modified" | awk -F': ' '{print \$2}')

        # 读取之前保存的 Last-Modified 时间
        if [ -f "\$LAST_MOD_FILE" ]; then
            OLD_LAST_MOD=\$(cat "\$LAST_MOD_FILE")
        else
            OLD_LAST_MOD=""
        fi

        # 比较新的和旧的 Last-Modified 时间
        if [ "\$NEW_LAST_MOD" != "\$OLD_LAST_MOD" ]; then
            echo "\$(date): New version detected for \$FILE_NAME. Downloading update..." >> "\$LOG_FILE"
            if curl -s -L -o "\$FILE_PATH" "\$URL"; then
                echo "\$(date): Download completed successfully for \$FILE_NAME." >> "\$LOG_FILE"
            else
                echo "\$(date): Error occurred while downloading \$FILE_NAME." >> "\$LOG_FILE"
            fi
            echo "\$NEW_LAST_MOD" > "\$LAST_MOD_FILE"
        else
            echo "\$(date): No update available for \$FILE_NAME." >> "\$LOG_FILE"
        fi
    fi
done
EOL

# 赋予脚本执行权限
sudo chmod +x /var/www/html/telegram_update/check_and_download_telegram.sh

# 运行更新脚本
sudo bash /var/www/html/telegram_update/check_and_download_telegram.sh

# 设置定时任务
(crontab -l 2>/dev/null; echo "*/5 * * * * /var/www/html/telegram_update/check_and_download_telegram.sh") | crontab -

# 提供访问链接
echo "设置完成。您可以通过以下链接访问您的应用："
echo "http://$(hostname -I | awk '{print $1}'):$PORT/index.php"

# Docker 部署 MTProto 代理
echo "正在部署 MTProto 代理..."
if [ "$(docker ps -q -f name=mtproto-proxy)" ]; then
    echo "MTProto 代理容器已存在，停止并删除现有容器..."
    docker stop mtproto-proxy
    docker rm mtproto-proxy
fi

docker pull telegrammessenger/proxy
docker run -d -p $MT_PROTO_PORT:443 --name mtproto-proxy --restart=always -v proxy-config:/data -e SECRET=ab9b40530c90ef7bd07d892802008734 telegrammessenger/proxy:latest

# 提取代理链接
sleep 5
tg_link=$(docker logs mtproto-proxy 2>&1 | grep -o 'tg://proxy?server=[^ ]*' | head -n 1)
tme_link=$(docker logs mtproto-proxy 2>&1 | grep -o 'https://t.me/proxy?server=[^ ]*' | head -n 1)

# 获取主机 IP 地址和外部端口
HOST_IP=$(hostname -I | awk '{print $1}')
EXTERNAL_PORT=$MT_PROTO_PORT  # 使用脚本中的 MTProto 代理外部端口号

# 替换链接中的端口为外部端口号
tg_link_external="tg://proxy?server=${HOST_IP}&port=${EXTERNAL_PORT}&secret=ab9b40530c90ef7bd07d892802008734"
tme_link_external="https://t.me/proxy?server=${HOST_IP}&port=${EXTERNAL_PORT}&secret=ab9b40530c90ef7bd07d892802008734"

# 保存链接到文件
echo "保存代理链接到文件..."
sudo tee /var/private_data/proxy_links.txt > /dev/null <<EOL
TG Link: $tg_link_external
T.me Link: $tme_link_external
EOL

# 输出代理链接
echo "TG 代理链接: $tg_link_external"
echo "T.me 代理链接: $tme_link_external"

# 设置每天重启 MTProto 代理容器的定时任务
echo "设置每天重启 MTProto 代理容器的定时任务..."
(crontab -l 2>/dev/null; echo "0 0 * * * docker restart mtproto-proxy") | crontab -

echo "所有设置完成。"
