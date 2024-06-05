#!/bin/bash

### Add helm repos
helm repo add stable https://charts.helm.sh/stable
helm repo add minio https://charts.min.io
helm repo add grafana https://grafana.github.io/helm-charts

### Create namespace
kubectl create ns cs
```

### NFS Provisioner
helm install nfs-provisioner stable/nfs-server-provisioner \
--set persistence.enabled=true \
--set persistence.size="100Gi" \
--set storageClass.name=nfs \
-n cs --debug

### minio
helm install minio minio/minio \
-n cs -f minio_values.yaml --debug

### Grafana
helm install -n cs \
grafana grafana/grafana \
-f grafana_values.yaml \
--debug

#### create API key:
export GRAFANA_API_KEY=$(kubectl -n cs exec deploy/grafana -- \
sh -c 'curl -u $GF_SECURITY_ADMIN_USER:$GF_SECURITY_ADMIN_PASSWORD -X POST \
-H "Content-Type: application/json" \
-d "{\"name\":\"logger-app-key\",\"role\":\"Admin\"}" \
http://localhost:3000/api/auth/keys' | jq -r .key);
kubectl -n cs create secret generic grafana-api-key --from-literal=grafana-api-key="$GRAFANA_API_KEY"

#### verify key is available:
kubectl -n cs get secret grafana-api-key -o jsonpath="{.data.grafana-api-key}" | base64 --decode

### Loki
helm install -n cs \
loki grafana/loki-stack \
-f loki_values.yaml \
--debug

### Promtail
kubectl apply -f promtail_configmap.yaml
kubectl apply -f promtail_deploy.yaml

### Log archive handler
kubectl -n cs create configmap scripts \
  --from-file=downloader_extractor.sh \
  --from-file=grafana_dashboard_automation.py
kubectl apply -f extracted_logs_pvc.yaml
kubectl apply -f log_handler_deploy.yaml

### Check if stack is ready
labels=(
    "app=loki"
    "app.kubernetes.io/instance=grafana"
    "app=log-archive-handler"
    "app.kubernetes.io/instance=loki"
    "app=minio"
    "app=nfs-server-provisioner"
    "app=promtail"
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

echo "cs-logger stack is ready"