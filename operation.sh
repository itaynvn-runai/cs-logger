#!/bin/bash

NS="$1"

if [ -z "$NS" ]; then
    NS="cs"
fi

expose() {
    local service_name=$1
    local port=$2
    local ns=$NS

    if tmux ls 2>/dev/null | grep -qE "^${service_name}:"; then
        echo "Session for ${service_name} is already running."
        tmux ls
    else
        echo "No session for ${service_name} found, exposing service in a detached shell:"
        tmux new-session -d -s ${service_name} "kubectl -n $ns port-forward deploy/${service_name} ${port}"
        tmux ls
    fi

    address="http://localhost:${port}"
    until curl -s --output /dev/null --head --fail "$address"; do
        echo "Waiting for $address to become available..."
        sleep 5
    done
    echo "$service_name is available at $address!"
}

echo "activating cs-logger stack in '$NS' namespace"

if command -v tmux &> /dev/null
then
    echo "tmux utility found"
else
    echo "tmux utility not found, installing:"
    brew install tmux
fi

expose "code-server" 8080
expose "minio" 9001

echo "all services are running!"
