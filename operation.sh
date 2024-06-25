#!/bin/bash

NS="$1"

if [ -z "$NS" ]; then
    NS="cs"
fi

echo "activating cs-logger stack in '$NS' namespace"

if command -v tmux &> /dev/null
then
    echo "tmux utility found"
else
    echo "tmux utility not found, installing:"
    brew install tmux
fi

if tmux ls 2>/dev/null | grep -qE '^(grafana|minio):'
then
    echo "sessions already running:"
    tmux ls
else
    echo "no sessions found, exposing services in detached shells:"
    tmux new-session -d -s vscode "kubectl -n $NS port-forward deploy/code-server 8080"
    tmux new-session -d -s minio "kubectl -n $NS port-forward deploy/minio 9001"
    tmux ls
fi

check_address() {
    local address=$1
    until curl -s --output /dev/null --head --fail "$address"; do
        echo "Waiting for $address to become available..."
        sleep 5
    done
    echo "$address is available!"
}

check_address "http://localhost:9001"
check_address "http://localhost:8080"