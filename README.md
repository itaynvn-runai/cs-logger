# cs-logger
upload log archives and view them neatly in grafana

## Install from scratch

### NFS Provisioner
*Enables using an RWX storage class.*

Install:
```
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

### Loki
*Data source plugin for grafana, allows ingestion of raw text files.*

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

### Log extractor

Create PVC:
```
kubectl apply -f extracted_logs_pvc.yaml
```

Create CronJob:
```
kubectl apply -f log_extractor_cronjob.yaml
```

### Dashboard auto-creator
TBA

## Operation

### Uploading Logs

with kubeconfig in-place, expose minio and grafana UI locally:
```
kubectl -n cs port-forward deploy/minio 9001
```
enter [http://localhost:9001/](http://localhost:9001/)
choose the "new-log-archives" bucket
upload the `tar.gz` file.

### Viewing logs

expose grafana:
```
kubectl -n cs port-forward deploy/grafana 3000
```

enter [http://localhost:3000/](http://localhost:3000/)