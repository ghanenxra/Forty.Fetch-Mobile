# Required Binaries

This project requires external binaries to function properly. Due to GitHub file size limits, these binaries are NOT included in the repository.

You must manually download and place the following binaries in their respective directories:

## Android Binaries
Place the compiled `.so` files for FFmpeg, FFprobe, and YT-DLP inside the following directory before compiling the APK:
`android/app/src/main/jniLibs/arm64-v8a/`
- `libffmpeg.so`
- `libffprobe.so`
- `libytdlp.so`

## Windows Binaries (For local testing)
Place the Windows `.exe` files in the `assets/` directory:
- `assets/ffmpeg.exe`
- `assets/ffprobe.exe`
- `assets/yt-dlp.exe`

(Alternatively, on Windows, the app will auto-deploy these to your AppData roaming folder if they are bundled in assets).
