#!/bin/bash

# ==============================================================================
# AV1 Bridge
# 1. Creates a clean file (Video + Audio only) for Direct Play.
# 2. Extracts the first subtitle track to an external .srt file.
# ==============================================================================

echo "Scanning directory: $(pwd)"
count=0

# Loop through files
for f in *; do
  [ -f "$f" ] || continue
  
  # Check for MKV/WebM
  if [[ "${f,,}" == *.mkv || "${f,,}" == *.webm ]]; then
    ((count++))
    
    base_name="${f%.*}"
    out_video="${base_name}.mp4"
    out_sub="${base_name}.srt"
    
    echo "---------------------------------------------------"
    echo "File: $f"
    echo "  > Action: Remuxing to MP4 + Extracting SRT"
    printf "  > Status: Working"

    # Run FFmpeg in background
    # -sn : Disable internal subtitles in the MP4
    # -map 0:s:0 : Select the first subtitle track for the SRT file
    ffmpeg -y -nostats -loglevel quiet -i "$f" \
      -map 0:v:0 -c:v copy -tag:v av01 \
      -map 0:a   -c:a aac -b:a 192k \
      -sn -movflags +faststart \
      "$out_video" \
      -map 0:s:0? "$out_sub" &

    # Progress Spinner
    pid=$!
    while kill -0 $pid 2>/dev/null; do
        printf "."
        sleep 0.5
    done
    wait $pid

    # Check for success
    if [ $? -eq 0 ]; then
        echo " [Done]"
        
        # Cleanup: Check if the SRT file is valid (not empty)
        # If the source had no subtitles, ffmpeg creates an empty file.
        if [ ! -s "$out_sub" ]; then
            rm "$out_sub"
            echo "  > Note: No subtitles found (SRT removed)."
        fi
    else
        echo " [Error]"
        echo "  > Failed to process file."
    fi
  fi
done

if [ "$count" -eq 0 ]; then
  echo "Error: No matching files found."
fi
