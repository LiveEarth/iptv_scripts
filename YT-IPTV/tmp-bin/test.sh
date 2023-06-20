#!/bin/bash
youtube_url="https://www.youtube.com/watch?v=6RVB15TsHEQ"
#youtube_url="https://youtube.com/playlist?list=PLWKufwzhZ_M_oDUCHXjexDscF8n2gBp0A"

# Fetch video information using yt-dlp command
output=$(./yt-dlp_linux -i --get-id -e -o '%(upload_date)s' -f 22 -g --get-filename --get-duration -- "$youtube_url")

# Generate m3u playlist
echo "#EXTM3U"
echo "# generated from $youtube_url"
# Store the output in an array, splitting on newline
IFS=$'\n' read -d '' -r -a lines <<< "$output"

# Process the lines in batches of 5
batch_size=5
total_lines=${#lines[@]}
num_batches=$((total_lines / batch_size))

for ((i = 0; i < num_batches; i++)); do
  start=$((i * batch_size))
  end=$(((i + 1) * batch_size))
  # Process the current batch
  for ((j = start; j < end; j++)); do
    line="${lines[j]}"
    # Perform your desired operations on the line
    echo "THE Line: $line"
  done

#    video_title=$(echo "$line" | sed -n '1p')
#    video_id=$(echo "$line" | sed -n '2p')
#    video_url=$(echo "$line" | sed -n '3p')
#    video_date=$(echo "$line" | sed -n '4p')
#    video_duration=$(echo "$line" | sed -n '5p')
#    echo "video_title: $video_title"
#    echo "video_id: $video_id"
#    echo "video_url: $video_url"
#    echo "video_date: $video_date"
#    echo "video_duration: $video_duration"
#  done
#    echo "#EXTINF:$video_duration,YT $video_date $video_title"
#    echo "$video_url"
  # Optionally, you can add a delay between batches
#  sleep 1
  echo "------------"
done

# Process any remaining lines that didn't fit into a full batch
remaining_lines=$((total_lines % batch_size))
if [[ $remaining_lines -gt 0 ]]; then
  start=$((num_batches * batch_size))

  # Process the remaining lines
  for ((j = start; j < total_lines; j++)); do
    line="${lines[j]}"
    # Perform your desired operations on the line
    echo "$line"
  done
echo "=========="
fi
