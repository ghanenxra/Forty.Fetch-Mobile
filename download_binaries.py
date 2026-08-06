import os
import urllib.request
import tarfile
import zipfile
import tempfile
import shutil

def download_file(url, dest_path):
    print(f"Downloading {url} to {dest_path}...")
    try:
        urllib.request.urlretrieve(url, dest_path)
        print(f"Successfully downloaded to {dest_path}")
        return True
    except Exception as e:
        print(f"Failed to download {url}: {e}")
        return False

def extract_ffmpeg_tarxz(tar_path, dest_dir):
    print(f"Extracting FFmpeg from {tar_path}...")
    try:
        with tarfile.open(tar_path, "r:xz") as tar:
            for member in tar.getmembers():
                if member.isfile() and (member.name.endswith("/ffmpeg") or member.name.endswith("/ffprobe")):
                    basename = os.path.basename(member.name)
                    member.name = f"lib{basename}.so"
                    tar.extract(member, dest_dir)
                    print(f"Extracted {member.name} to {dest_dir}")
        return True
    except Exception as e:
        print(f"Failed to extract FFmpeg: {e}")
        return False

def main():
    # Ensure jniLibs directories exist
    arm64_dir = os.path.join("forty_fetch_mobile", "android", "app", "src", "main", "jniLibs", "arm64-v8a")
    os.makedirs(arm64_dir, exist_ok=True)
    
    # 1. Download yt-dlp (arm64)
    yt_dlp_url = "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_linux_aarch64"
    yt_dlp_dest = os.path.join(arm64_dir, "libytdlp.so")
    download_file(yt_dlp_url, yt_dlp_dest)
    
    # 2. Download and extract FFmpeg/FFprobe (arm64) from official yt-dlp builds
    ffmpeg_url = "https://github.com/yt-dlp/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-linuxarm64-gpl.tar.xz"
    
    with tempfile.TemporaryDirectory() as tmpdir:
        tar_path = os.path.join(tmpdir, "ffmpeg.tar.xz")
        if download_file(ffmpeg_url, tar_path):
            extract_ffmpeg_tarxz(tar_path, arm64_dir)
            
    print("\nAll required binaries for arm64-v8a have been downloaded and placed in the assets directory!")
    print("You can now compile the app.")

if __name__ == "__main__":
    main()
