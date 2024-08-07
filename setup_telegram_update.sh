#!/bin/bash



# 定义默认值
DEFAULT_PORT=81
DEFAULT_MT_PROTO_PORT=443
DEFAULT_USERNAME="admin"
DEFAULT_PASSWORD="admin"
DEFAULT_DOMAIN="yourdomain.com"

# 读取用户输入
read -p "请输入Apache端口号 [默认: $DEFAULT_PORT]: " PORT
read -p "请输入MTProto代理端口号: " MT_PROTO_PORT
read -p "请输入用户名 [默认: $DEFAULT_USERNAME]: " USERNAME
read -sp "请输入密码 [默认: $DEFAULT_PASSWORD]: " PASSWORD
echo
read -p "请输入您的域名 [默认: $DEFAULT_DOMAIN]: " DOMAIN

# 使用默认值如果用户没有输入
PORT=${PORT:-$DEFAULT_PORT}
MT_PROTO_PORT=${PORT:-$DEFAULT_MT_PROTO_PORT}
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

# 安装和更新系统
echo "正在更新系统并安装 Docker..."

# 安装 Docker
install_docker() {
    if [ "$OS_NAME" == "centos" ]; then
        sudo yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine
        sudo yum install -y yum-utils
        sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        sudo systemctl start docker
        sudo docker run hello-world

    elif [ "$OS_NAME" == "debian" ]; then
        for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove -y $pkg; done
        sudo apt-get update
        sudo apt-get install -y ca-certificates curl
        sudo install -m 0755 -d /etc/apt/keyrings
        sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        sudo docker run hello-world

    elif [ "$OS_NAME" == "ubuntu" ]; then
        for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove -y $pkg; done
        sudo apt-get update
        sudo apt-get install -y ca-certificates curl
        sudo install -m 0755 -d /etc/apt/keyrings
        sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        sudo docker run hello-world

    elif [ "$OS_NAME" == "rhel" ]; then
        sudo yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine podman runc
        sudo yum install -y yum-utils
        sudo yum-config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
        sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        sudo systemctl start docker
        sudo docker run hello-world

    elif [ "$OS_NAME" == "fedora" ]; then
        sudo dnf remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-selinux docker-engine-selinux docker-engine
        sudo dnf -y install dnf-plugins-core
        sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
        sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        sudo systemctl start docker
        sudo docker run hello-world

    else
        echo "不支持的操作系统。"
        exit 1
    fi
}

# 调用安装 Docker 的函数
install_docker


# 安装 Apache 和 PHP
echo "正在安装 Apache 和 PHP..."
if [ "$OS_NAME" == "ubuntu" ] || [ "$OS_NAME" == "debian" ]; then
    sudo apt install -y apache2 php libapache2-mod-php php-cli php-curl php-zip curl

elif [ "$OS_NAME" == "centos" ] || [ "$OS_NAME" == "rhel" ]; then
    sudo yum install -y httpd php php-cli php-curl php-zip curl

elif [ "$OS_NAME" == "fedora" ]; then
    sudo dnf install -y httpd php php-cli php-curl php-zip curl
fi

# 配置防火墙
echo "正在配置防火墙..."
if [ "$OS_NAME" == "ubuntu" ] || [ "$OS_NAME" == "debian" ]; then
    sudo ufw allow $PORT/tcp
    sudo ufw allow $MT_PROTO_PORT/tcp
    sudo ufw enable

elif [ "$OS_NAME" == "centos" ] || [ "$OS_NAME" == "rhel" ]; then
    sudo firewall-cmd --permanent --add-port=$PORT/tcp
    sudo firewall-cmd --permanent --add-port=$MT_PROTO_PORT/tcp
    sudo firewall-cmd --reload

elif [ "$OS_NAME" == "fedora" ]; then
    sudo firewall-cmd --add-port=$PORT/tcp --permanent
    sudo firewall-cmd --add-port=$MT_PROTO_PORT/tcp --permanent
    sudo firewall-cmd --reload
fi

# 更新 Apache 配置文件，监听自定义端口
echo "正在更新 Apache 配置文件..."
if [ "$OS_NAME" == "ubuntu" ] || [ "$OS_NAME" == "debian" ]; then
    sudo tee /etc/apache2/ports.conf > /dev/null <<EOL
Listen 80
Listen 442
Listen $PORT
Listen $MT_PROTO_PORT
EOL

elif [ "$OS_NAME" == "centos" ] || [ "$OS_NAME" == "rhel" ] || [ "$OS_NAME" == "fedora" ]; then
    sudo tee /etc/httpd/conf/httpd.conf > /dev/null <<EOL
Listen 80
Listen 442
Listen $PORT
Listen $MT_PROTO_PORT
EOL
fi

# 创建虚拟主机配置
echo "正在创建虚拟主机配置..."
if [ "$OS_NAME" == "ubuntu" ] || [ "$OS_NAME" == "debian" ]; then
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
    sudo a2ensite telegram_update
    sudo a2enmod php
    sudo a2enmod mpm_prefork
    sudo systemctl restart apache2

elif [ "$OS_NAME" == "centos" ] || [ "$OS_NAME" == "rhel" ] || [ "$OS_NAME" == "fedora" ]; then
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
fi

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
            echo "\$(date): Initial download completed successfully for \$FILE_NAME." >> "\$LOG_FILE"
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

# 提取 tg:// 和 t.me 链接
tg_link=$(docker logs mtproto-proxy 2>&1 | grep -o 'tg://[^ ]*' | head -n 1)
tme_link=$(docker logs mtproto-proxy 2>&1 | grep -o 'https://t.me/[^ ]*' | head -n 1)


# 假设之前已经完成了 Docker 的安装和配置

# 拉取 Telegram 代理 Docker 镜像
docker pull telegrammessenger/proxy

# 启动容器
docker run -d -p$MT_PROTO_PORT:443 --name=mtproto-proxy --restart=always -v proxy-config:/data telegrammessenger/proxy:latest

# 等待容器启动
sleep 5

# 提取 tg:// 和 t.me 链接
tg_link=$(docker logs mtproto-proxy 2>&1 | grep -o 'tg://proxy?server=[^ ]*' | head -n 1)
tme_link=$(docker logs mtproto-proxy 2>&1 | grep -o 'https://t.me/proxy?server=[^ ]*' | head -n 1)

# 显示链接
echo "TG Link: $tg_link"
echo "T.me Link: $tme_link"



# 保存链接到文件
echo "TG Link: $tg_link" > /var/private_data/proxy_links.txt
echo "T.me Link: $tme_link" >> /var/private_data/proxy_links.txt

# 输出结果以便用户查看
echo "Links have been saved to /var/private_data/proxy_links.txt"
