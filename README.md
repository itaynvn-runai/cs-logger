# cs-logger
stack for uploading log archives (generated by `runai-adm collect-logs` command) and viewing log files in a centralized location

## Overview
upload `*.tar.gz` archive to minio bucket, then an automated pipeline:
- extracts archive
- organizes folders
- injects log files to datasource
- wraps them in grafana dashboard

pros:
- provides an easy to browse interface
- logs are displayed neatly
- enables quick search within files
- allows sharing with other team members

## Operation
if the cs-logger stack already installed on cluster, run this to expose minio and Grafana locally:
```
bash fast_operation.sh
```

### Upload log archives
1. enter minio UI: [http://localhost:9001/](http://localhost:9001/) (creds are in values/secret)
2. choose the "**new-log-archives**" bucket
3. upload the `tar.gz` file

### Display logs
1. enter grafana UI: [http://localhost:3000/](http://localhost:3000/) (creds are in values/secret)
2. select "**Dashboards**", then choose the folder with the name of the log archive you uploaded.
3. in that folder, there will be a dashboard for each log file, click on the file you wish to display.
4. to expand the panel to full screen, click "**Show context**" icon on any line in that log file.

### tmux cheatsheet
- **list running sessions**: `tmux ls`
- **attach to a running session**: `tmux a -t SESSION_NAME`
- **detach from session**: press `CTRL`+`B`, then press `D`
- **terminate running session**: `tmux kill-ses -t SESSION_NAME`

## Install

run this to deploy cs-logger stack in an empty cluster:
```
bash fast_deployment.sh
```

stack includes:
- **NFS Provisioner**: Enables using an RWX storage class
- **minio**: S3 compatible object storage, provides a simple file upload interface
- **Grafana**: Visualizer for metrics/logs, allows displaying the logs neatly
- **Loki**: Data source plugin for grafana
- **Promtail**: ingests raw text files and pushes to Loki
- **Log archive handler**: automation script for handling log archives files

## Future improvements
- have the customers send the log files directly to the object storage
(eliminating the need to send attach the file to salesforce ticket, and us downloading it)
- (requires RnD approval/participation) send log files to the object storage, **directly** from the `runai-adm` CLI tool
