#!/bin/bash

set +e

FPS=2

# 0. get destination directory check exists. make if not! (from user)
# 1. find where "VIDEO" label is mounted
# 2. list all .h264 (excluding tmp.*)
# 3. for each file, use ffmpeg -> destination dir
destination_dir=$1

[ $# -eq 0 ] && { echo "Usage: $0 dir-name"; exit 1; }

if [ ! -d ${destination_dir} ]
then
  echo "Directory ${destination_dir} DOES NOT exists."
  exit 1
fi

echo "Saving videos on ${destination_dir}"


video_dir=$(lsblk -o mountpoint,label | grep "VIDEOS" | cut -f 1 -d ' ')

for file in $(ls ${video_dir}/*.h264 | grep -v tmp\.);
  do

    basename=$(basename $file)
    output_file=${destination_dir}/${basename%.h264}.mp4
    echo "$file -> $output_file"
    ffmpeg -r ${FPS} -i ${file}  -vcodec copy  -y ${output_file}  -loglevel panic
  done
#


