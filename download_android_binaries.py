import os
import urllib.request
import zipfile
import tempfile
import shutil

def download_file(url, dest_path):
    print(f"Downloading {url} to {dest_path}...")
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req) as response, open(dest_path, 'wb') as out_file:
            shutil.copyfileobj(response, out_file)
        print(f"Successfully downloaded to {dest_path}")
        return True
    except Exception as e:
        print(f"Failed to download {url}: {e}")
        return False

def extract_zip(zip_path, dest_dir):
    print(f"Extracting {zip_path}...")
    try:
        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            zip_ref.extractall(dest_dir)
            print(f"Extracted to {dest_dir}")
        return True
    except Exception as e:
        print(f"Failed to extract zip: {e}")
        return False

def main():
    arm64_dir = os.path.join("forty_fetch_mobile", "android", "app", "src", "main", "jniLibs", "arm64-v8a")
    os.makedirs(arm64_dir, exist_ok=True)
    
    with tempfile.TemporaryDirectory() as tmpdir:
        # Download the sample APK which contains the pre-compiled Android .so files
        apk_url = "https://github.com/yausername/youtubedl-android/releases/download/0.18.1/app-arm64-v8a-debug.apk"
        apk_path = os.path.join(tmpdir, "app.apk")
        if download_file(apk_url, apk_path):
            extract_zip(apk_path, tmpdir)
            
            # The APK contains lib/arm64-v8a/libytdlp.so and libffmpeg.so
            src_ytdlp = os.path.join(tmpdir, "lib", "arm64-v8a", "libytdlp.so")
            src_ffmpeg = os.path.join(tmpdir, "lib", "arm64-v8a", "libffmpeg.so")
            src_ffprobe = os.path.join(tmpdir, "lib", "arm64-v8a", "libffprobe.so")
            
            if os.path.exists(src_ytdlp):
                shutil.copy(src_ytdlp, os.path.join(arm64_dir, "libytdlp.so"))
                print("Successfully extracted libytdlp.so from APK to jniLibs!")
            else:
                print("Error: libytdlp.so not found in APK!")
                
            if os.path.exists(src_ffmpeg):
                shutil.copy(src_ffmpeg, os.path.join(arm64_dir, "libffmpeg.so"))
                print("Successfully extracted libffmpeg.so from APK to jniLibs!")
            else:
                print("Error: libffmpeg.so not found in APK!")
                
            if os.path.exists(src_ffprobe):
                shutil.copy(src_ffprobe, os.path.join(arm64_dir, "libffprobe.so"))
                print("Successfully extracted libffprobe.so from APK to jniLibs!")

if __name__ == "__main__":
    main()
