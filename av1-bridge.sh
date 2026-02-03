#!/bin/bash

# ==============================================================================
# 1. Remuxes video (Copy).
# 2. Converts audio (AAC).
# 3. Extracts SRT subtitles to external file (Best for Jellyfin/Chrome).
# 4. Supports custom output containers.
# ==============================================================================

# --- Argument Parsing ---
args=("$@")
last_arg="${args[${#args[@]}-1]}"
input_exts=()
output_ext=".mp4" # Default

# Check if last argument is an output extension (starts with .)
if [[ "$last_arg" == .* ]]; then
  output_ext="$last_arg"
  input_exts=("${args[@]:0:${#args[@]}-1}")
else
  input_exts=("${args[@]}")
fi

# Default inputs if empty
if [ ${#input_exts[@]} -eq 0 ]; then
  input_exts=("mkv" "webm")
fi

echo "Configuration:"
echo "  > Inputs: ${input_exts[*]}"
echo "  > Output: $output_ext"
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
    
    echo "---------------------------------------------------"
    echo "File: $f"
    echo "  > Action: Remuxing to $output_ext + Extracting SRT"
    printf "  > Status: Working"

    # FFmpeg Command
    # -sn: Drop internal subtitles (prevents Transcoding issues)
    # -map 0:s:0: Extract first subtitle to external file
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

    if [ $? -eq 0 ]; then
        echo " [Done]"
        # Cleanup empty SRTs
        if [ ! -s "$out_sub" ]; then
            rm "$out_sub"
            echo "  > Note: No subtitles found (SRT removed)."
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
