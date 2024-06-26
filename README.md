# cs-logger
stack for uploading log archives (generated by `runai-adm collect-logs` command) and viewing log files in a centralized location

## Overview
upload `*.tar.gz` archive to minio bucket, then an automated pipeline:
- extracts archive
- organizes folders
- displays them in web-based VScode

pros:
- provides an easy to browse interface
- logs are displayed neatly
- enables quick search within files
- allows sharing with other team members

## Operation
if the cs-logger stack already installed on cluster, run this to expose minio and Grafana locally:
```
bash operation.sh
```

the `cs` namespace is used by default, to choose a different namespace run:
```
bash operation.sh NAMESPACE
```

the script creates 2 detached shells using `tmux` utility, for exposing minio and vscode UI locally.

### Upload log archives
1. enter minio UI: [http://localhost:9001/](http://localhost:9001/) (creds are in values/secret)
2. choose the "**new-log-archives**" bucket for `*.tar.gz` archives, or "**new-single-files**" bucket for any other text file
3. Drag and drop the file to the bucket (it will be immediatly processed and then moved to the **done** bucket by the file handler)

### Display logs
1. enter VScode: [http://localhost:8080/](http://localhost:8080/) (password is `admin`)
2. select "**Files**" tab on the left panel (the root folder `/data/extracted-logs` will be open by default)
3. **archives** are extracted into subfolders with the same name (plus a human-formatted date appended to it), for example:
archive file `runai-logs-1583069400.tar.gz` will be extracted into subfolder `runai-logs-1583069400_01-03-2020_15-30`
4. **text files** will be available in the root folder.

### tmux cheatsheet
- **list running sessions**: `tmux ls`
- **attach to a running session**: `tmux a -t SESSION_NAME`
- **detach from session**: press `CTRL`+`B`, then press `D`
- **terminate running session**: `tmux kill-ses -t SESSION_NAME`

## Install

run this to deploy cs-logger stack in an empty cluster:
```
bash deployment.sh
```

the `cs` namespace is used by default, to choose a different namespace run:
```
bash deployment.sh NAMESPACE
```

stack includes:
- **NFS Provisioner**: Enables using an RWX storage class
- **minio**: S3 compatible object storage, provides a simple file upload interface
- **Log archive handler**: automation script for handling log archives files
- **VScode**: web-based version of VScode, for displaying log files