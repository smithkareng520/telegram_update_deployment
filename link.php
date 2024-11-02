<?php
session_start();
if (!isset($_SESSION['loggedin']) || !$_SESSION['loggedin']) {
    header('Location: index.php');
    exit();
}

// 定义文件路径
$authFile = '/var/private_data/auth.txt';
$filePath = '/var/private_data/proxy_links.txt';
$fileContent = '';

// 检查文件是否存在
if (file_exists($filePath)) {
    $fileContent = file_get_contents($filePath);
} else {
    echo "File not found.";
    exit;
}

// 分割文件内容为行
$lines = explode("\n", $fileContent);

// 初始化链接
$tgLink = '';
$tmeLink = '';

// 解析链接
foreach ($lines as $line) {
    if (strpos($line, 'TG Link:') === 0) {
        $tgLink = trim(substr($line, 8));
    } elseif (strpos($line, 'T.me Link:') === 0) {
        $tmeLink = trim(substr($line, 10));
    }
}

// 检查是否提交了新代理的端口
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $mtProtoPort = intval($_POST['mtProtoPort']);
    
    // 进行端口号的基本验证
    if ($mtProtoPort < 1024 || $mtProtoPort > 65535) {
        echo "请输入有效的端口号（范围：1024-65535）";
        exit;
    }

    // 删除现有的 MTProto 代理容器
    exec('sudo docker stop mtproto-proxy 2>&1', $outputStop, $return_var_stop);
    exec('sudo docker rm mtproto-proxy 2>&1', $outputRm, $return_var_rm);

    // 检查停止和删除命令的返回值
    if ($return_var_stop !== 0) {
        echo "停止容器失败: " . implode("\n", $outputStop);
        exit;
    }
    if ($return_var_rm !== 0) {
        echo "删除容器失败: " . implode("\n", $outputRm);
        exit;
    }

    // 生成随机的 MTProto 密钥
    $secret = bin2hex(random_bytes(16));

    // 运行新的 MTProto 代理容器
    exec("sudo docker run -d -p $mtProtoPort:443 --name mtproto-proxy --restart=always -v proxy-config:/data -e SECRET=$secret telegrammessenger/proxy:latest 2>&1", $outputRun, $return_var_run);

    // 检查运行命令的返回值
    if ($return_var_run !== 0) {
        echo "创建新容器失败: " . implode("\n", $outputRun);
        exit;
    }

    // 获取服务器的外部 IP 地址
    $host_ip = trim(file_get_contents('https://api.ipify.org'));

    // 提取新代理链接
    sleep(3); // 等待容器启动
    $tgLink = "tg://proxy?server=$host_ip&port=$mtProtoPort&secret=$secret";
    $tmeLink = "https://t.me/proxy?server=$host_ip&port=$mtProtoPort&secret=$secret";

    // 保存新代理链接到文件
    file_put_contents($authFile, "SECRET:$secret\n");

    // 追加新链接到 proxy_links.txt
    file_put_contents($filePath, "TG Link: $tgLink\nT.me Link: $tmeLink\n", FILE_APPEND);

    echo "新的 MTProto 代理已创建！<br>";
}

// 生成 HTML 内容
echo <<<HTML
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Telegram Proxy Links</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
        }
        .link-container {
            margin: 10px 0;
        }
        .link-container textarea {
            width: 100%;
            height: 50px;
            margin-bottom: 10px;
            font-size: 16px;
            padding: 10px;
            border: 1px solid #ccc;
            border-radius: 4px;
            resize: none;
        }
        .switch-container {
            margin-top: 10px;
            display: flex;
            align-items: center;
        }
        .switch {
            position: relative;
            display: inline-block;
            width: 60px;
            height: 34px;
        }
        .switch input {
            opacity: 0;
            width: 0;
            height: 0;
        }
        .slider {
            position: absolute;
            cursor: pointer;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background-color: #ccc;
            transition: .4s;
            border-radius: 34px;
        }
        .slider:before {
            position: absolute;
            content: "";
            height: 26px;
            width: 26px;
            border-radius: 50%;
            background-color: white;
            left: 4px;
            bottom: 4px;
            transition: .4s;
        }
        input:checked + .slider {
            background-color: #007bff;
        }
        input:checked + .slider:before {
            transform: translateX(26px);
        }
    </style>
</head>
<body>
    <h1>Telegram Proxy Links</h1>
    <div id="links-container" class="link-container">
        <span>当前链接:</span>
        <textarea id="link-text" readonly>$tgLink</textarea>
        <button id="copy-button" onclick="copyToClipboard()">复制链接</button>
        <br>
        <div class="switch-container">
            <label class="switch">
                <input type="checkbox" id="link-toggle" onclick="toggleLink()">
                <span class="slider"></span>
            </label>
            <span id="switch-label" class="switch-label">TG Link</span>
        </div>
    </div>

    <h2>创建新 MTProto 代理</h2>
    <form method="POST">
        <label for="mtProtoPort">输入 MTProto 代理端口号：</label>
        <input type="number" id="mtProtoPort" name="mtProtoPort" required>
        <br><br>
        <button type="submit">生成新代理</button>
    </form>

    <script>
        // Initial link to be copied
        let tgLink = '$tgLink';
        let tmeLink = '$tmeLink';
        let currentLink = tgLink;

        document.getElementById('link-text').value = currentLink;

        function copyToClipboard() {
            if (navigator.clipboard) {
                navigator.clipboard.writeText(currentLink).then(() => {
                    alert('链接已复制到剪贴板！');
                }).catch(err => {
                    alert('复制链接失败: ' + err);
                });
            } else {
                // Fallback for older browsers
                const textarea = document.createElement('textarea');
                textarea.value = currentLink;
                document.body.appendChild(textarea);
                textarea.select();
                try {
                    document.execCommand('copy');
                    alert('链接已复制到剪贴板！');
                } catch (err) {
                    alert('使用回退方法复制链接失败: ' + err);
                }
                document.body.removeChild(textarea);
            }
        }

        function toggleLink() {
            const isChecked = document.getElementById('link-toggle').checked;
            currentLink = isChecked ? tmeLink : tgLink;
            document.getElementById('switch-label').textContent = isChecked ? 'T.me Link' : 'TG Link';
            document.getElementById('link-text').value = currentLink;
        }
    </script>
</body>
</html>
HTML;
?>
