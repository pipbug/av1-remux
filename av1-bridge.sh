#!/bin/bash

args=("$@")
last_arg="${args[${#args[@]}-1]}"
input_exts=()
output_ext=".mp4" # Default to Apple/Universal

# Check if last argument is an output extension (starts with .)
if [[ "$last_arg" == .* ]]; then
  output_ext="$last_arg"
  input_exts=("${args[@]:0:${#args[@]}-1}")
else
  input_exts=("${args[@]}")
fi

# Default inputs
if [ ${#input_exts[@]} -eq 0 ]; then
  input_exts=("mkv" "webm")
fi

# Set codecs based on the target container
if [[ "$output_ext" == ".mp4" || "$output_ext" == ".mov" ]]; then
    # APPLE / UNIVERSAL MODE
    audio_opts="-c:a aac -b:a 192k"
    video_tag="-tag:v av01"
    sub_opts="-sn" # Drop internal subs (Use external SRT)
    
elif [[ "$output_ext" == ".webm" ]]; then
    # CHROME / WEB MODE
    # Chrome prefers Opus audio. It handles AV1 natively without the Apple tag.
    audio_opts="-c:a libopus -b:a 128k"
    video_tag="" # WebM doesn't need the Apple tag
    sub_opts="-sn" 

elif [[ "$output_ext" == ".mkv" ]]; then
    # ARCHIVE MODE
    audio_opts="-c:a copy" # Keep original audio
    video_tag=""
    sub_opts="-c:s copy" # Keep original subs
fi

echo "Configuration:"
echo "  > Target: $output_ext"
echo "  > Audio:  $audio_opts"
echo "  > Video:  Copy (AV1) $video_tag"
echo "---------------------------------------------------"
echo "Scanning directory: $(pwd)"
count=0

# --- Main Loop ---
for ext in "${input_exts[@]}"; do
  clean_ext="${ext#.}"
  shopt -s nocaseglob nullglob
  
  for f in *."$clean_ext"; do
    ((count++))
    base_name="${f%.*}"
    out_video="${base_name}${output_ext}"
    out_sub="${base_name}.srt"

    # Collision check
    if [[ "$f" == "$out_video" ]]; then
        out_video="${base_name}_remux${output_ext}"
    fi
    
    echo "---------------------------------------------------"
    echo "File: $f"
    echo "  > Action: Remuxing to $output_ext"
    printf "  > Status: Working"

    # Run FFmpeg
    ffmpeg -y -nostats -loglevel quiet -i "$f" \
      -map 0:v:0 -c:v copy $video_tag \
      -map 0:a   $audio_opts \
      $sub_opts -movflags +faststart \
      "$out_video" \
      -map 0:s:0? "$out_sub" &

    pid=$!
    while kill -0 $pid 2>/dev/null; do
        printf "."
        sleep 0.5
    done
    wait $pid

    if [ $? -eq 0 ]; then
        echo " [Done]"
        if [[ "$sub_opts" == "-sn" ]]; then
             if [ ! -s "$out_sub" ]; then
                rm "$out_sub" 2>/dev/null
             fi
        else
            # If we kept internal subs (MKV), we don't need the external file
            rm "$out_sub" 2>/dev/null
        fi
    else
        echo " [Error]"
    fi
  done
  shopt -u nocaseglob nullglob
done

if [ "$count" -eq 0 ]; then
  echo "Error: No matching files found."
fi
