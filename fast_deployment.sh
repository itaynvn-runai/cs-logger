#!/bin/bash

### Add helm repos
helm repo add stable https://charts.helm.sh/stable
helm repo add minio https://charts.min.io
helm repo add grafana https://grafana.github.io/helm-charts

### Create namespace
kubectl create ns cs

### NFS Provisioner
helm install nfs-provisioner stable/nfs-server-provisioner \
--set persistence.enabled=true \
--set persistence.size="100Gi" \
--set storageClass.name=nfs \
-n cs --debug

### minio
helm install minio minio/minio \
-n cs -f minio_values.yaml --debug

### Log archive handler
kubectl -n cs create configmap scripts \
  --from-file=downloader_extractor.sh \
  --from-file=grafana_dashboard_automation.py
kubectl apply -f extracted_logs_pvc.yaml
kubectl apply -f log_handler_deploy.yaml

### VScode
git clone https://github.com/coder/code-server
helm -n cs install code-server code-server/ci/helm-chart \
-f vscode_values.yaml --debug

### Check if stack is ready
labels=(
    "app=log-archive-handler"
    "app=minio"
    "app=nfs-server-provisioner"
    "app.kubernetes.io/instance=code-server"
)

is_pod_running() {
    local pod_name=$1
    local pod_status=$(kubectl -n cs get pod "$pod_name" -o jsonpath='{.status.phase}' 2>/dev/null)
    if [[ "$pod_status" == "Running" ]]; then
        echo "Pod '$pod_name' is up and running."
    else
        echo "Pod '$pod_name' is not in the 'Running' state."
    fi
}

for label in "${labels[@]}"; do
    echo "Checking pods with label '$label'..."
    pod_names=($(kubectl -n cs get pods -l "$label" --no-headers | awk '{ print $1 }' 2>/dev/null))
    for pod_name in "${pod_names[@]}"; do
        is_pod_running "$pod_name"
    done
done

echo "cs-logger stack is ready!"