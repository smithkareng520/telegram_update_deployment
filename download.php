<?php
header('Content-Type: application/json');

// 读取 JSON 输入
$input = file_get_contents('php://input');
$data = json_decode($input, true);

if (!isset($data['url']) || !isset($data['quality'])) {
    echo json_encode(['success' => false, 'message' => '缺少参数']);
    exit;
}

$url = escapeshellarg($data['url']);
$quality = escapeshellarg($data['quality']);

// 定义 Python 脚本路径
$pythonScriptPath = '/var/www/html/telegram_update/download_script.py';

// 构建命令
$command = "python3 $pythonScriptPath $url $quality";

// 执行 Python 脚本
exec($command, $output, $return_var);

// 根据执行结果返回 JSON 响应
if ($return_var === 0) {
    echo json_encode(['success' => true]);
} else {
    echo json_encode(['success' => false, 'message' => '下载失败']);
}
?>
