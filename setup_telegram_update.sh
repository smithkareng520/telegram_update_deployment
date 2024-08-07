#!/bin/bash

# 设置默认值
DEFAULT_APACHE_PORT=81
DEFAULT_MT_PROTO_PORT=443
DEFAULT_USERNAME="admin"
DEFAULT_PASSWORD="admin"
DEFAULT_DOMAIN="yourdomain.com"

# 用户输入提示
echo "请输入配置参数（按Enter键使用默认值）"
read -p "Apache 端口号 [默认: $DEFAULT_APACHE_PORT]: " INPUT_APACHE_PORT
read -p "MTProto 代理外部端口号 [默认: $DEFAULT_MT_PROTO_PORT]: " INPUT_MT_PROTO_PORT
read -p "用户名 [默认: $DEFAULT_USERNAME]: " INPUT_USERNAME
read -sp "密码 [默认: $DEFAULT_PASSWORD]: " INPUT_PASSWORD
echo
read -p "域名 [默认: $DEFAULT_DOMAIN]: " INPUT_DOMAIN

# 使用默认值或用户输入的值
APACHE_PORT=${INPUT_APACHE_PORT:-$DEFAULT_APACHE_PORT}
MT_PROTO_PORT=${INPUT_MT_PROTO_PORT:-$DEFAULT_MT_PROTO_PORT}
USERNAME=${INPUT_USERNAME:-$DEFAULT_USERNAME}
PASSWORD=${INPUT_PASSWORD:-$DEFAULT_PASSWORD}
DOMAIN=${INPUT_DOMAIN:-$DEFAULT_DOMAIN}

# 检查端口是否被占用的函数
check_port() {
    local port=$1
    local prompt=$2
    local variable=$3

    while netstat -tuln | grep ":$port\b" >/dev/null; do
        echo "错误: 端口 $port 已被占用，请输入一个不同的端口。"
        read -p "$prompt" NEW_PORT
        eval "$variable=\${NEW_PORT:-$port}"
        port=${NEW_PORT:-$port}
    done
}

# 检查 Apache 端口是否被占用
check_port $APACHE_PORT "Apache 端口号 [默认: $DEFAULT_APACHE_PORT]: " APACHE_PORT

# 检查 MTProto 代理端口是否被占用
check_port $MT_PROTO_PORT "MTProto 代理外部端口号 [默认: $DEFAULT_MT_PROTO_PORT]: " MT_PROTO_PORT

# 显示配置
echo "使用的配置如下："
echo "Apache 端口号: $APACHE_PORT"
echo "MTProto 代理外部端口号: $MT_PROTO_PORT"
echo "用户名: $USERNAME"
echo "域名: $DOMAIN"

# 检查操作系统
echo "正在识别操作系统..."
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_NAME=$ID
    OS_VERSION=$VERSION_ID
else
    echo "无法识别操作系统，退出脚本。"
    exit 1
fi

echo "操作系统: $OS_NAME $OS_VERSION"

# 安装 Docker 函数
install_docker() {
    echo "正在安装 Docker..."
    case "$OS_NAME" in
        centos|rhel)
            sudo yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine
            sudo yum install -y yum-utils
            sudo yum-config-manager --add-repo https://download.docker.com/linux/$OS_NAME/docker-ce.repo
            sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        ubuntu|debian)
            for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove -y $pkg; done
            sudo apt-get update
            sudo apt-get install -y ca-certificates curl gnupg
            sudo install -m 0755 -d /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/$OS_NAME/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$OS_NAME $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        fedora)
            sudo dnf remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-selinux docker-engine-selinux docker-engine
            sudo dnf -y install dnf-plugins-core
            sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
            sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        *)
            echo "不支持的操作系统，退出脚本。"
            exit 1
            ;;
    esac
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo docker run hello-world
}

# 安装 Docker
install_docker

# 安装 Apache 和 PHP
echo "正在安装 Apache 和 PHP..."
if [[ "$OS_NAME" == "ubuntu" || "$OS_NAME" == "debian" ]]; then
    sudo apt install -y apache2 php libapache2-mod-php php-cli php-curl php-zip curl
elif [[ "$OS_NAME" == "centos" || "$OS_NAME" == "rhel" ]]; then
    sudo yum install -y httpd php php-cli php-curl php-zip curl
elif [ "$OS_NAME" == "fedora" ]; then
    sudo dnf install -y httpd php php-cli php-curl php-zip curl
else
    echo "不支持的操作系统，退出脚本。"
    exit 1
fi

# 配置防火墙
echo "正在配置防火墙..."
if [[ "$OS_NAME" == "ubuntu" || "$OS_NAME" == "debian" ]]; then
    sudo ufw allow $APACHE_PORT/tcp
    sudo ufw reload
elif [[ "$OS_NAME" == "centos" || "$OS_NAME" == "rhel" || "$OS_NAME" == "fedora" ]]; then
    sudo firewall-cmd --permanent --add-port=$APACHE_PORT/tcp
    sudo firewall-cmd --reload
else
    echo "不支持的操作系统，无法配置防火墙。"
fi

# 更新 Apache 配置
echo "正在更新 Apache 配置文件..."
update_apache_config() {
    if [[ "$OS_NAME" == "ubuntu" || "$OS_NAME" == "debian" ]]; then
        if ! grep -q "Listen $APACHE_PORT" /etc/apache2/ports.conf; then
            sudo sed -i "\$aListen $APACHE_PORT" /etc/apache2/ports.conf
        fi
    elif [[ "$OS_NAME" == "centos" || "$OS_NAME" == "rhel" || "$OS_NAME" == "fedora" ]]; then
        if ! grep -q "Listen $APACHE_PORT" /etc/httpd/conf/httpd.conf; then
            sudo sed -i "\$aListen $APACHE_PORT" /etc/httpd/conf/httpd.conf
        fi
    fi
}

# 更新 Apache 配置
update_apache_config

# 创建虚拟主机配置
create_vhost_config() {
    echo "正在创建虚拟主机配置..."
    local conf_file
    local vhost_dir

    if [[ "$OS_NAME" == "ubuntu" || "$OS_NAME" == "debian" ]]; then
        conf_file="/etc/apache2/sites-available/telegram_update.conf"
        vhost_dir="/var/www/html/telegram_update"
        if [ -f $conf_file ]; then
            echo "虚拟主机配置文件已存在，覆盖更新..."
        else
            sudo mkdir -p $vhost_dir
            sudo tee $conf_file > /dev/null <<EOL
<VirtualHost *:$APACHE_PORT>
    ServerAdmin webmaster@$DOMAIN
    DocumentRoot $vhost_dir
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined

    <Directory $vhost_dir>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOL
            sudo a2ensite telegram_update.conf
            sudo a2enmod php
            sudo systemctl restart apache2
        fi
    elif [[ "$OS_NAME" == "centos" || "$OS_NAME" == "rhel" || "$OS_NAME" == "fedora" ]]; then
        conf_file="/etc/httpd/conf.d/telegram_update.conf"
        vhost_dir="/var/www/html/telegram_update"
        if [ -f $conf_file ]; then
            echo "虚拟主机配置文件已存在，覆盖更新..."
        else
            sudo mkdir -p $vhost_dir
            sudo tee $conf_file > /dev/null <<EOL
<VirtualHost *:$APACHE_PORT>
    ServerAdmin webmaster@$DOMAIN
    DocumentRoot $vhost_dir
    ErrorLog logs/error_log
    CustomLog logs/access_log common

    <Directory $vhost_dir>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOL
            sudo systemctl restart httpd
        fi
    fi
}

# 创建虚拟主机配置
create_vhost_config

# 创建安全目录
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
sudo tee /var/www/html/telegram_update/check_and_download_telegram.sh > /dev/null <<EOL
#!/bin/bash

URL="https://updates.tdesktop.com/tlinux/tsetup.tar.xz"
FILE_PATH="/var/www/html/telegram_update/tsetup.tar.xz"
LAST_MOD_FILE="/var/www/html/telegram_update/last_modified.txt"
LOG_FILE="/var/www/html/telegram_update/update.log"

if [ ! -f "\$FILE_PATH" ]; then
    echo "\$(date): \$FILE_PATH not found. Downloading initial version..." >> "\$LOG_FILE"
    if curl -s -L -o "\$FILE_PATH" "\$URL"; then
        echo "\$(date): Initial download completed successfully." >> "\$LOG_FILE"
    else
        echo "\$(date): Error occurred while downloading." >> "\$LOG_FILE"
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
        echo "\$(date): New version detected. Downloading update..." >> "\$LOG_FILE"
        if curl -s -L -o "\$FILE_PATH" "\$URL"; then
            echo "\$(date): Download completed successfully." >> "\$LOG_FILE"
        else
            echo "\$(date): Error occurred while downloading." >> "\$LOG_FILE"
        fi
        echo "\$NEW_LAST_MOD" > "\$LAST_MOD_FILE"
    else
        echo "\$(date): No update available." >> "\$LOG_FILE"
    fi
fi
EOL
sudo chmod +x /var/www/html/telegram_update/check_and_download_telegram.sh

# 运行更新脚本
echo "正在运行更新脚本..."
sudo /var/www/html/telegram_update/check_and_download_telegram.sh

# 设置定时任务
echo "设置定时任务..."
(crontab -l 2>/dev/null; echo "*/5 * * * * /var/www/html/telegram_update/check_and_download_telegram.sh") | crontab -

# 提供访问链接
echo "设置完成。您可以通过以下链接访问您的应用："
echo "http://$(hostname -I | awk '{print $1}'):$APACHE_PORT"

# Docker 部署 MTProto 代理

echo "正在部署 MTProto 代理..."
if [ "$(docker ps -q -f name=mtproto-proxy)" ]; then
    echo "MTProto 代理容器已存在，停止并删除现有容器..."
    docker stop mtproto-proxy
    docker rm mtproto-proxy
fi

docker pull telegrammessenger/proxy
docker run -d -p443:443 --name mtproto-proxy --restart=always -v proxy-config:/data -e SECRET=00baadf00d15abad1deaa51sbaadcafe telegrammessenger/proxy:latest
# 提取代理链接
sleep 5
tg_link=$(docker logs mtproto-proxy 2>&1 | grep -o 'tg://proxy?server=[^ ]*' | head -n 1)
tme_link=$(docker logs mtproto-proxy 2>&1 | grep -o 'https://t.me/proxy?server=[^ ]*' | head -n 1)

# 保存链接到文件
echo "保存代理链接到文件..."
sudo tee /var/private_data/proxy_links.txt > /dev/null <<EOL
TG Link: $tg_link
T.me Link: $tme_link
EOL

# 输出代理链接
echo "TG 代理链接: $tg_link"
echo "T.me 代理链接: $tme_link"
