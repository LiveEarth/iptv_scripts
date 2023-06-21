#!/bin/bash
# youtube_url="https://www.youtube.com/watch?v=6RVB15TsHEQ"
youtube_url="https://youtube.com/playlist?list=PLkwbnbw8dfH0chZq7boolPdj1g9LB6ihf"

# Fetch video information using yt-dlp command
output=$(./yt-dlp_linux -i --get-id -e -o '%(upload_date)s' -f 22 -g --get-filename --get-duration -- "$youtube_url")

declare -A videoproperties

# Generate m3u playlist
echo "#EXTM3U"
echo -e "# generated from $youtube_url \n"

# Store the output in an array, splitting on newline
IFS=$'\n' read -d '' -r -a lines <<< "$output"

# Process the lines in batches of 5
batch_size=5
total_lines=${#lines[@]}
num_batches=$((total_lines / batch_size))

for ((i = 0; i < num_batches; i++)); do
  start=$((i * batch_size))
  end=$(((i + 1) * batch_size))

  # Store the lines in the current batch
  current_batch=("${lines[@]:$start:$batch_size}")

  # Set variable names using case statements
  variable_name_1="videotitle"
  variable_name_2="videoid"
  variable_name_3="videourl"
  variable_name_4="videodate"
  variable_name_5="videolength"

  # Print the variables with modified names
  for ((j = 0; j < batch_size; j++)); do
    line="${current_batch[j]}"
    variable_name=""

    case $j in
      0) variable_name="$variable_name_1" ;;
      1) variable_name="$variable_name_2" ;;
      2) variable_name="$variable_name_3" ;;
      3) variable_name="$variable_name_4" ;;
      4) variable_name="$variable_name_5" ;;
      *) variable_name="Variable $j" ;;
    esac

    videoproperties["$variable_name"]="$line"
  done

  echo "#EXTINF:${videoproperties["videolength"]},YT ${videoproperties["videodate"]} ${videoproperties["videotitle"]}"
  echo "${videoproperties["videourl"]}"
  echo
done
