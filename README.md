# cs-logger
stack for uploading log archives and viewing log files in a centralized location

## Install

### Create namespace
```
kubectl create ns cs
```

### NFS Provisioner
*Enables using an RWX storage class.*

Install:
```
helm repo add stable https://charts.helm.sh/stable

helm install nfs-provisioner stable/nfs-server-provisioner \
--set persistence.enabled=true \
--set persistence.size="100Gi" \
--set storageClass.name=nfs \
-n cs --debug
```

### minio
*S3 compatible object storage. provides a simple file upload interface*

install:

```
helm repo add minio https://charts.min.io/

helm install minio minio/minio \
-n cs -f minio_values.yaml --debug
```

#### Grafana
*Visualizer for metrics/logs. allows displaying the logs neatly.*

install:
```
helm install -n cs \
grafana grafana/grafana \
-f grafana_values.yaml \
--debug
```

once grafana is up and running, create an API key:
```
export GRAFANA_API_KEY=$(kubectl -n cs exec deploy/grafana -- \
sh -c 'curl -u $GF_SECURITY_ADMIN_USER:$GF_SECURITY_ADMIN_PASSWORD -X POST \
-H "Content-Type: application/json" \
-d "{\"name\":\"logger-app-key\",\"role\":\"Admin\"}" \
http://localhost:3000/api/auth/keys' | jq -r .key);
kubectl -n cs create secret generic grafana-api-key --from-literal=grafana-api-key="$GRAFANA_API_KEY"
```

optional - verify key is available:
```
kubectl -n cs get secret grafana-api-key -o jsonpath="{.data.grafana-api-key}" | base64 --decode
```

### Loki
*Data source plugin for grafana*

install:
```
helm repo add grafana https://grafana.github.io/helm-charts

helm install -n cs \
loki grafana/loki-stack \
-f loki_values.yaml \
--debug
```

### Promtail
*ingests raw text files and pushes to Loki*

install:
```
kubectl apply -f promtail_configmap.yaml
kubectl apply -f promtail_deploy.yaml
```

### Log archive handler
*app that scans bucket for new archives, extracts their content and creates a grafana dashboard for each folder*

Create script configmap:
```
kubectl -n cs create configmap scripts \
  --from-file=downloader_extractor.sh \
  --from-file=grafana_dashboard_automation.py
```

Create PVC:
```
kubectl apply -f extracted_logs_pvc.yaml
```

Create deployment:
```
kubectl apply -f log_handler_deploy.yaml
```

## Operation
### Expose services locally
with kubeconfig in-place, expose minio and grafana UI locally:
```
kubectl -n cs port-forward deploy/minio 9001
kubectl -n cs port-forward deploy/grafana 3000
```
its recommended to run port-forward in detached shells, to make sure it doesn't stop by mistake.

- use tmux for this purpose:
```
brew install tmux
```
- then expose minio and grafana in detached shells:
```
tmux new-session -d -s grafana 'kubectl -n cs port-forward deploy/grafana 3000'
tmux new-session -d -s minio 'kubectl -n cs port-forward deploy/minio 9001'
```
- **optional:** attach to a running session:
```
tmux a -t grafana
tmux a -t minio
```
- **optional:** detach from current session: press `CTRL`+`B`, then press `D`
- **optional:**  terminate session:
```
tmux kill-ses -t grafana
tmux kill-ses -t minio
```

### Upload log archives
1. enter minio UI: [http://localhost:9001/](http://localhost:9001/) (creds are in values/secret)
2. choose the "**new-log-archives**" bucket
3. upload the `tar.gz` file

### Display logs
1. enter grafana UI: [http://localhost:3000/](http://localhost:3000/) (creds are in values/secret)
2. select "**Dashboards**", then choose the dashboard with the name of the log archive you uploaded.
3. in the dashboard, there will be a panel for each log file.
4. to expand the panel to full screen, click "**Show context**" icon on any line in that log file.