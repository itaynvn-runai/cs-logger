#!/bin/bash

mkdir -p /data/extracted_logs
echo "###   Fetching Min.IO Client..."
curl -o "mc" https://dl.min.io/client/mc/release/linux-amd64/mc
chmod +x ./mc && mv ./mc /bin/ && mc --version
echo "###   Connecting to new bucket..."
mc alias set myminio http://minio:9000 $MINIO_ROOT_USER $MINIO_ROOT_PASSWORD
cd /scripts
while true; do
    output=$(mc ls myminio/new-log-archives)
    if echo "$output" | grep -q "\.tar\.gz"; then
        echo "###   Found new archive files!"
        echo "$output" | while read -r line; do
            file_name=$(echo "$line" | awk '{print $6}')
            echo "###   Handling file $file_name..."
            echo "###   Downloading archive $file_name..."
            mc cp --recursive myminio/new-log-archives/$file_name /data
            echo "###   Archive download complete, listing path..."
            file_name_path="/data/$file_name"
            ls -lah $file_name_path
            echo "###   Starting extraction..."
            tar -xf $file_name_path -C /data/extracted_logs/
            subfolder="${file_name%.*.*}"
            unix_time=${subfolder:11}
            human_time=$(date -d "@$unix_time" "+%d-%m-%Y_%H-%M")
            old_subfolder_path="/data/extracted_logs/$subfolder"
            subfolder_path="$old_subfolder_path"_"$human_time"
            mv $old_subfolder_path/ $subfolder_path/
            echo "###   Extracted $file_name to $subfolder_path"
            ls -la $subfolder_path
            rm -rf $file_name_path
            echo "###   Deleted $file_name_path (locally)"
            mc mv myminio/new-log-archives/$file_name myminio/old-log-archives/
            echo "###   Moved $file_name to old bucket"
            echo "###   Done handling file $file_name"
        done
    else
        echo "###   No archive files found, trying again..."
        sleep 20
    fi
done