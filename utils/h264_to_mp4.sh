#!/bin/bash

# use: h264_to_mp4.sh <out_dir>

set +e

FPS=2
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


