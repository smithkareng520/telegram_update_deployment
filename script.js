// script.js
document.getElementById('download-form').addEventListener('submit', function(event) {
    event.preventDefault(); // 防止表单默认提交

    const url = document.getElementById('video-url').value;
    const quality = document.getElementById('quality').value;
    const statusElement = document.getElementById('status');

    statusElement.textContent = '下载中...';

    fetch('download.php', { // PHP 文件处理请求
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ url, quality })
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            statusElement.textContent = '下载完成！';
        } else {
            statusElement.textContent = '下载失败，请重试。';
        }
    })
    .catch(error => {
        console.error('Error:', error);
        statusElement.textContent = '下载失败，请重试。';
    });
});
