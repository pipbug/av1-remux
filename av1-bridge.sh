#!/bin/bash

# ==============================================================================
# AV1 Remuxer
# Usage: ./script.sh [input_ext1] ... [.output_ext]
# Example: ./script.sh mkv .mov   (Converts MKVs to MOV)
# Example: ./script.sh            (Defaults to MKV/WebM -> MP4)
# ==============================================================================

args=("$@")
last_arg="${args[${#args[@]}-1]}"
input_exts=()
output_ext=".mp4" # Default Output

if [[ "$last_arg" == .* ]]; then
  output_ext="$last_arg"
  # Use all args except the last as input extensions
  input_exts=("${args[@]:0:${#args[@]}-1}")
else
  input_exts=("${args[@]}")
fi

# Default inputs if none provided
if [ ${#input_exts[@]} -eq 0 ]; then
  input_exts=("mkv" "webm")
fi

# 2. Configure Subtitle Logic based on Output
# MP4/MOV need "mov_text". MKV supports everything ("copy").
if [[ "$output_ext" == ".mkv" ]]; then
   sub_codec="copy"
else
   sub_codec="mov_text"
fi

echo "Configuration:"
echo "  > Inputs: ${input_exts[*]}"
echo "  > Output: $output_ext"
echo "  > Subs:   $sub_codec"
echo "------------"
echo "Scanning directory: $(pwd)"
count=0

# 3. Main Loop
for ext in "${input_exts[@]}"; do
  clean_ext="${ext#.}" # Remove dot if user typed ".mkv"
  shopt -s nocaseglob nullglob
  
  for f in *."$clean_ext"; do
    ((count++))
    out="${f%.*}$output_ext"
    
    echo "------------"
    echo "File: $f"
    echo "  > Action: REMUXING -> $output_ext"
    printf "  > Status: Working"

    # ATTEMPT 1: Remux + Keep Subtitles
    ffmpeg -y -nostats -loglevel quiet -i "$f" \
      -map 0:v:0 -c:v copy -tag:v av01 \
      -map 0:a   -c:a aac -b:a 192k \
      -map 0:s?  -c:s "$sub_codec" \
      -movflags +faststart \
      "$out" &
    
    # Progress Spinner
    pid=$!
    while kill -0 $pid 2>/dev/null; do
        printf "."
        sleep 0.5
    done
    wait $pid

    # Check Success
    if [ $? -eq 0 ]; then
        echo " [Done]"
    else
        echo ""
        echo "  > [!] Subtitle Error. Retrying (Dropping subtitles)..."
        printf "  > Status: Working (no subtitles)..."
        
        # ATTEMPT 2: Fallback (Drop Subtitles)
        ffmpeg -y -nostats -loglevel quiet -i "$f" \
           -map 0:v:0 -c:v copy -tag:v av01 \
           -map 0:a   -c:a aac -b:a 192k \
           -sn \
           -movflags +faststart \
           "$out" &
        
        pid=$!
        while kill -0 $pid 2>/dev/null; do
            printf "."
            sleep 0.5
        done
        wait $pid
        echo " [Done]"
    fi
  done
  shopt -u nocaseglob nullglob
done

if [ "$count" -eq 0 ]; then
  echo "Error: No matching files found."
fi
