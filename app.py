from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
import yt_dlp
import subprocess
import os
import logging

app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "*"}})  # 允许所有来源访问

# 配置日志
logging.basicConfig(level=logging.DEBUG, format='%(asctime)s - %(levelname)s - %(message)s')

# 配置路径
DOWNLOAD_DIRECTORY = '/var/www/html/telegram_update/downloads'
SCRIPT_PATH = '/var/www/html/telegram_update/download_script.py'

def run_download_script(url, quality, output_file):
    """运行下载脚本"""
    command = ['python3', SCRIPT_PATH, url, quality, output_file]
    logging.debug(f"Running command: {' '.join(command)}")
    result = subprocess.run(command, capture_output=True, text=True)
    if result.returncode != 0:
        logging.error(f"Download script error: {result.stderr}")
        raise RuntimeError(f"Download script error: {result.stderr}")
    logging.debug(f"Download script output: {result.stdout}")
    return result.stdout

@app.route('/get_formats', methods=['GET'])
def get_formats():
    """获取视频格式"""
    url = request.args.get('url')
    if not url:
        return jsonify({'error': 'No URL provided'}), 400
    try:
        ydl_opts = {
            'format': 'bestaudio/best',
            'noplaylist': True,
        }
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(url, download=False)
            formats = info.get('formats', [])
            return jsonify([{
                'format_id': f['format_id'],
                'format_note': f.get('format_note', 'No note available'),
                'url': f.get('url', 'No URL available'),
                'resolution': f.get('resolution', 'No resolution available'),
                'quality': f.get('format_note', 'No quality information available')
            } for f in formats])
    except Exception as e:
        logging.error(f"Error fetching formats: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/download', methods=['POST'])
def download():
    """处理下载请求"""
    data = request.json
    url = data.get('url')
    quality = data.get('quality')

    if not url or not quality:
        return jsonify({'error': 'URL and quality are required'}), 400

    output_file = 'output_video.mp4'  # 可以根据需要动态设置文件名
    output_path = os.path.join(DOWNLOAD_DIRECTORY, output_file)

    try:
        # 执行下载脚本
        run_download_script(url, quality, output_path)

        # 检查文件是否存在
        if not os.path.isfile(output_path):
            raise FileNotFoundError(f"File not found: {output_path}")

        return jsonify({
            'success': True,
            'message': 'Download and conversion completed',
            'download_url': f'http://45.77.170.55:81/downloads/{output_file}'
        }), 200
    except FileNotFoundError as fnf_error:
        logging.error(f"File not found: {fnf_error}")
        return jsonify({'error': str(fnf_error)}), 404
    except RuntimeError as re_error:
        logging.error(f"Runtime error: {re_error}")
        return jsonify({'error': str(re_error)}), 500
    except Exception as e:
        logging.error(f"Error during download: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/downloads/<filename>')
def download_file(filename):
    """提供下载文件"""
    try:
        return send_from_directory(DOWNLOAD_DIRECTORY, filename)
    except FileNotFoundError:
        return jsonify({'error': 'File not found'}), 404

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
