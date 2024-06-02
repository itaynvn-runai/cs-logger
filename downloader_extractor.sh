#!/bin/bash

file_name=$1
echo "###   Downloading archive $file_name..."
mc cp --recursive myminio/new-log-archives/$file_name /data
echo "###   Archive download complete, listing path..."
file_name_path="/data/$file_name"
ls -lah $file_name_path
echo "###   Starting extraction process..."
tar -xf $file_name_path -C /data/extracted_logs/
subfolder="${file_name%.*.*}"
subfolder_path="/data/extracted_logs/$subfolder"
echo "###   Extracted $file_name to $subfolder_path"
ls -la $subfolder_path
rm -rf $file_name_path
echo "###   Deleted $file_name_path (locally)"
mc mv myminio/new-log-archives/$file_name myminio/old-log-archives/
echo "###   Moved $file_name to old bucket"