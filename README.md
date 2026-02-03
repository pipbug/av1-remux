# av1-bridge
A simple bash script to remux AV1 video files (`.mkv`, `.webm`) into more widely compatible `.mp4` containers. Watch your AV1 library on web browsers and Apple devices without transcoding! It should get most devices playing AV1 natively by applying the correct metadata tags.

## What it does

-  **Remuxes Video:** Copies the AV1 video stream directly (no quality loss, disk-speed fast).
-  **Fixes Compatibility:** Adds the `av01` tag so QuickTime/iOS/Finder recognize the file.
-   **Normalizes Audio:** Converts audio to AAC (192k) for broad compatibility.
-   **Handles Subtitles:**
    * Converts text subs (SRT) to `mov_text`.
    * Detects image subs (PGS) that break MP4s and automatically drops them instead of crashing.

## Usage

Grab the script, make it executable, and run it in a folder with your video files.

```bash
chmod +x av1-bridge.sh
./av1-bridge.sh
```
You can also pass specific extensions if you want:
```bash
./av1-bridge.sh mkv webm
```
## Requirements
- ffmpeg (Must be installed and in your PATH)
- Linux, macOS, WSL

## How it works
It's essentially running this FFmpeg one-liner, wrapped in a loop with some error checking for subtitles:

```bash
ffmpeg -i input.mkv \
  -c:v copy -tag:v av01 \   # The important bit for Apple support
  -c:a aac \
  -c:s mov_text \
  -movflags +faststart \
  output.mp4
```
## License
MIT. Do whatever you want with it.
