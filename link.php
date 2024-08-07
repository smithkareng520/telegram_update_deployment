<?php
// 读取文件内容
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
        .copy-feedback {
            font-style: italic;
            color: green;
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
        .switch-label {
            margin-left: 10px;
        }
        .switch-container button {
            margin-top: 10px;
            padding: 10px 20px;
            border: none;
            color: white;
            background-color: #007bff;
            cursor: pointer;
            border-radius: 4px;
            font-size: 16px;
            transition: background-color 0.3s;
        }
        .switch-container button:hover {
            background-color: #0056b3;
        }
    </style>
</head>
<body>
    <h1>Telegram Proxy Links</h1>
    <div id="links-container" class="link-container">
        <span>Current Link:</span>
        <textarea id="link-text" readonly>$tgLink</textarea>
        <button id="copy-button" onclick="copyToClipboard()">Copy Link</button>
        <br>
        <div class="switch-container">
            <label class="switch">
                <input type="checkbox" id="link-toggle" onclick="toggleLink()">
                <span class="slider"></span>
            </label>
            <span id="switch-label" class="switch-label">TG Link</span>
        </div>
    </div>
    <script>
        // Initial link to be copied
        let tgLink = '$tgLink';
        let tmeLink = '$tmeLink';
        let currentLink = tgLink;

        document.getElementById('link-text').value = currentLink;

        function copyToClipboard() {
            if (navigator.clipboard) {
                navigator.clipboard.writeText(currentLink).then(() => {
                    alert('Link copied to clipboard!');
                }).catch(err => {
                    alert('Failed to copy link: ' + err);
                });
            } else {
                // Fallback for older browsers
                const textarea = document.createElement('textarea');
                textarea.value = currentLink;
                document.body.appendChild(textarea);
                textarea.select();
                try {
                    document.execCommand('copy');
                    alert('Link copied to clipboard!');
                } catch (err) {
                    alert('Failed to copy link using fallback: ' + err);
                }
                document.body.removeChild(textarea);
            }
        }

        function toggleLink() {
            const isChecked = document.getElementById('link-toggle').checked;
            if (isChecked) {
                currentLink = tmeLink;
                document.getElementById('switch-label').textContent = 'T.me Link';
            } else {
                currentLink = tgLink;
                document.getElementById('switch-label').textContent = 'TG Link';
            }
            document.getElementById('link-text').value = currentLink;
        }
    </script>
</body>
</html>
HTML;
?>
