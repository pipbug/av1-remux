#!/bin/bash

echo "Scanning directory: $(pwd)"
count=0

for f in *; do
  [ -f "$f" ] || continue

  if [[ "${f,,}" == *.mkv || "${f,,}" == *.webm ]]; then
    
    ((count++))
    out="${f%.*}.mp4"
    echo "------"
    echo "File: $f"
    echo "  > Action: REMUXING (Direct Copy)"
    
    printf "  > Status: Working"

    ffmpeg -y -nostats -loglevel quiet -i "$f" \
      -map 0:v:0 -c:v copy -tag:v av01 \
      -map 0:a   -c:a aac -b:a 192k \
      -map 0:s?  -c:s mov_text \
      -movflags +faststart \
      "$out" &

    pid=$!

    while kill -0 $pid 2>/dev/null; do
        printf "."
        sleep 0.5
    done

    wait $pid
    if [ $? -eq 0 ]; then
        echo " [Done]"
    else
        echo ""
        echo "  > [!] Subtitle Error. Retrying (Dropping subtitles)..."
        printf "  > Status: Retrying"
        
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
        echo " [Done]"
    fi
  fi
done

if [ "$count" -eq 0 ]; then
  echo "Error: No .mkv or .webm files found."
fi
