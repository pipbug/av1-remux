# av1-bridge

**Universal AV1 Compatibility for Jellyfin, Chrome, and Apple.**

A bash utility that makes AV1 files play natively (**Direct Play**) on almost any client by separating the subtitles and standardizing the container.

## The Problem
* **Chrome/Jellyfin:** Cannot play MP4s with embedded subtitles (they force a server-side transcode just to render text).
* **Apple (iOS/tvOS):** Refuses to play AV1 unless it's in an MP4 container with a specific `av01` codec tag.
* **MKV:** Great for storage, terrible for web browser compatibility.

## The Solution
**av1-bridge** automates the fix:
1.  **Remuxes Video:** Copies the AV1 stream to MP4 (No quality loss).
2.  **Fixes Metadata:** Injects the `av01` tag for Apple support.
3.  **Preserves Audio:** Keeps **ALL** audio tracks (Dual Audio/Commentary) but converts them to AAC for compatibility.
4.  **Extracts Subtitles:** Removes internal subtitles and saves the first track as an external `.srt` file.

**Result:** A clean MP4 + SRT that Direct Plays on iPhone 15 Pro, Apple TV, Chrome, and Jellyfin/Plex Web.

---

## Quick Start

### 1. Install
Download `av1-bridge.sh` and make it executable:
```bash
chmod +x av1-bridge.sh
```
2. Run
Navigate to your movie folder and run the script:

```bash
# Convert to .mov (QuickTime friendly)
./av1-bridge.sh .mov

# Convert specific inputs/outputs
./av1-bridge.sh webm .mkv
```
It will scan for any .mkv or .webm files and process them automatically.

## How it works
It runs a specific FFmpeg chain designed for maximum compatibility:

```bash
ffmpeg -i input.mkv \
  -map 0:v:0 -c:v copy -tag:v av01 \   # Copy Video + Inject Apple Tag
  -map 0:a   -c:a aac -b:a 192k \      # Keep ALL Audio, convert to AAC
  -sn \                                # Remove internal subtitles (Fixes Chrome)
  output.mp4 \
  -map 0:s:0? output.srt               # Extract first sub track to file
```
## Important Notes
### Image Subtitles (PGS/VOBSUB)
If your source file is a Blu-ray rip with PGS (Image) subtitles, the .srt extraction will likely fail or produce an empty file. FFmpeg cannot convert images to text (OCR) natively.
Solution: You will need to source text subtitles (.srt) separately for these files.

### Subtitle Selection
The script currently extracts the first subtitle track (0:s:0).
For anime/dual-audio files, the first track is often just "Signs & Songs".
If you need the full dialogue track (often the second track), edit the script and change -map 0:s:0? to -map 0:s:1?.

### Requirements
- ffmpeg (must be in your $PATH)
- Linux, macOS, or WSL
