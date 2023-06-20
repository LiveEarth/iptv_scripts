#!/bin/bash
#youtube_url="https://www.youtube.com/watch?v=6RVB15TsHEQ"
youtube_url="https://youtube.com/playlist?list=PLWKufwzhZ_M_oDUCHXjexDscF8n2gBp0A"

# Fetch video information using yt-dlp command
output=$(./yt-dlp_linux -i --get-id -e -o '%(upload_date)s' -f 22 -g --get-filename --get-duration -- "$youtube_url")

# Generate m3u playlist
echo "#EXTM3U"
echo -e "# generated from $youtube_url \n"
# Store the output in an array, splitting on newline
IFS=$'\n' read -d '' -r -a lines <<< "$output"

# Process the lines in batches of 5
batch_size=5
total_lines=${#lines[@]}
num_batches=$((total_lines / batch_size))

# Declare an array to store the variables
declare -a line_variables

for ((i = 0; i < num_batches; i++)); do
  start=$((i * batch_size))
  end=$(((i + 1) * batch_size))
  # Process the current batch
  for ((j = start; j < end; j++)); do
    line="${lines[j]}"
    # Perform your desired operations on the line
#    echo "THE Line: $line"
    # Store the line in a variable
    line_variables[$j]=$line
  done
#  echo "------------"
done

# Process any remaining lines that didn't fit into a full batch
remaining_lines=$((total_lines % batch_size))
if [[ $remaining_lines -gt 0 ]]; then
  start=$((num_batches * batch_size))

  # Process the remaining lines
  for ((j = start; j < total_lines; j++)); do
    line="${lines[j]}"
    # Perform your desired operations on the line
    echo "THE Line: $line"
    # Store the line in a variable
    line_variables[$j]=$line
  done
echo "=========="
fi


# Set variable names using case statements
variable_name_1="videotitle"
variable_name_2="videoid"
variable_name_3="videourl"
variable_name_4="videodate"
variable_name_5="videolength"

declare -A videoproperties

# Print the variables with modified names
for ((i = 0; i < total_lines; i++)); do
  variable_name=""
  case $i in
    0) variable_name="$variable_name_1" ;;
    1) variable_name="$variable_name_2" ;;
    2) variable_name="$variable_name_3" ;;
    3) variable_name="$variable_name_4" ;;
    4) variable_name="$variable_name_5" ;;
    *) variable_name="Variable $i" ;;
  esac
#  echo "$variable_name: ${line_variables[$i]}"
videoproperties["$variable_name"]="${line_variables[$i]}"
done

# Accessing values
#echo "videotitle is: ${videoproperties["videotitle"]}"

echo "#EXTINF:${videoproperties["videolength"]},YT ${videoproperties["videodate"]} ${videoproperties["videotitle"]}"
echo "${videoproperties["videourl"]}"


# Iterating over the array
#for key in "${!videoproperties[@]}"
#do
#  echo "KEY $key is ${videoproperties[$key]}"
#done
