import sys
import yt_dlp
import subprocess
import os

def download_video(url, quality, output_file):
    # 设定 yt-dlp 选项
    ydl_opts = {
        'format': 'bestvideo+bestaudio/best',  # 确保下载最佳的视频和音频流
        'outtmpl': output_file,
        'merge_output_format': 'mp4',  # 合并音视频到 MP4
        'noplaylist': True,
        'quiet': False,
    }

    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            ydl.download([url])
    except Exception as e:
        print(f"Error downloading video: {e}")
        sys.exit(1)

def main():
    if len(sys.argv) != 4:
        print("Usage: python3 download_script.py <url> <quality> <output_file>")
        sys.exit(1)

    url = sys.argv[1]
    quality = sys.argv[2]
    output_file = sys.argv[3]

    # 创建文件夹如果不存在
    output_directory = os.path.dirname(output_file)
    if not os.path.exists(output_directory):
        os.makedirs(output_directory)

    # 下载视频
    download_video(url, quality, output_file)

    # 输出成功信息
    print(f"Video downloaded successfully to {output_file}")

if __name__ == "__main__":
    main()
