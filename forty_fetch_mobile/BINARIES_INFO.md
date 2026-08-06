# Required Native Binaries

This project relies on FFmpeg native Android binaries which are too large to be committed to version control.

To build the project correctly, you must place the appropriate `libffmpeg.so` file in the correct JNI architecture directories:

`android/app/src/main/jniLibs/<architecture>/libffmpeg.so`

You can use the python script provided in the root directory to automatically fetch the necessary `.so` files:

``bash
python download_android_binaries.py
``
