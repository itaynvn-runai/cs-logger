#!/bin/bash

NS="$1"

if [ -z "$NS" ]; then
    NS="cs"
fi

echo "deploying cs-logger stack in '$NS' namespace"

### Add helm repos
helm repo add stable https://charts.helm.sh/stable
helm repo add minio https://charts.min.io
helm repo add grafana https://grafana.github.io/helm-charts

### Create namespace
kubectl create ns $NS

### nfs-common validator
kubectl -n $NS apply -f daemonset_nfs_validator.yaml

### NFS Provisioner
helm install nfs-provisioner stable/nfs-server-provisioner \
-f values_nfs.yaml -n $NS --debug

### minio
helm install minio minio/minio \
-n $NS -f values_minio.yaml --debug

### Log archive handler
kubectl -n $NS create configmap scripts --from-file=file_handler.sh
kubectl -n $NS apply -f pvc_extracted_logs.yaml
kubectl -n $NS wait --for=condition=Bound pvc/extracted-logs --timeout=60s
kubectl -n $NS apply -f deployment_file_handler.yaml

### VScode
git clone https://github.com/coder/code-server
helm -n $NS install code-server code-server/ci/helm-chart \
-f values_vscode.yaml --debug

### Check if stack is ready
labels=(
    "app=log-archive-handler"
    "app=minio"
    "app=nfs-server-provisioner"
    "app.kubernetes.io/instance=code-server"
)

is_pod_running() {
    local pod_name=$1
    local pod_status=$(kubectl -n $NS get pod "$pod_name" -o jsonpath='{.status.phase}' 2>/dev/null)
    if [[ "$pod_status" == "Running" ]]; then
        echo "Pod '$pod_name' is up and running."
    else
        echo "Pod '$pod_name' is not in the 'Running' state."
    fi
}

for label in "${labels[@]}"; do
    echo "Checking pods with label '$label'..."
    pod_names=($(kubectl -n $NS get pods -l "$label" --no-headers | awk '{ print $1 }' 2>/dev/null))
    for pod_name in "${pod_names[@]}"; do
        is_pod_running "$pod_name"
    done
done

echo "cs-logger stack is ready!"
kubectl -n $NS get pods -o wide 