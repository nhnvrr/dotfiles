# Icons

Source: `@isoflow/isopacks@0.0.10` (1058 icons). Cache and catalog:

```bash
bun ~/.claude/skills/iso-diagram/scripts/icons.ts          # build once (compose does it too)
bun ~/.claude/skills/iso-diagram/scripts/icons.ts --force  # rebuild
grep -i 'redis' ~/.cache/iso-diagram/isopacks-0.0.10/catalog.tsv   # id, collection, iso|flat
```

| Collection | Count | Kind | Id prefix |
| --- | --- | --- | --- |
| isoflow | 37 | isometric drawings | none |
| aws | 319 | flat | `aws-` |
| gcp | 216 | flat | `gcp-` |
| azure | 447 | flat | `azure-` |
| kubernetes | 39 | flat | `k8s-` |

Isometric icons stand on the tile; flat ones are laid on a dark plinth.

## Common ids

**Generic (isoflow, isometric)**: `user laptop desktop mobiledevice server vm storage cache queue
loadbalancer router switch-module firewall cloud dns function-module package-module cronjob
document mail lock office block cube sphere pyramid diamond tower printer paymentcard
cardterminal image speech plane truck truck-2 mailmultiple`

**AWS**: `aws-ec2 aws-lambda aws-rds aws-aurora aws-dynamodb aws-simple-storage-service
aws-cloudfront aws-api-gateway aws-elastic-load-balancing aws-elasticache aws-route-53
aws-simple-queue-service aws-simple-notification-service aws-eventbridge aws-kinesis-data-streams
aws-elastic-container-service aws-eks-cloud aws-cognito aws-cloudwatch`

**GCP**: `gcp-cloud-run gcp-compute-engine gcp-cloud-sql gcp-cloud-storage gcp-bigquery
gcp-pubsub gcp-google-kubernetes-engine gcp-cloud-functions gcp-memorystore
gcp-cloud-load-balancing gcp-firestore gcp-cloud-cdn`

**Azure**: `azure-virtual-machine azure-app-services azure-function-apps azure-sql-database
azure-storage-accounts azure-kubernetes-services azure-cosmos-db azure-load-balancers
azure-service-bus azure-cache-redis azure-front-doors azure-application-gateways`

**Kubernetes**: `k8s-pod k8s-deploy k8s-rs k8s-sts k8s-ds k8s-svc k8s-ing k8s-ep k8s-cm
k8s-secret k8s-pv k8s-pvc k8s-vol k8s-sc k8s-ns k8s-node k8s-control-plane k8s-api k8s-etcd
k8s-sched k8s-c-m1 k8s-c-c-m k8s-kubelet k8s-k-proxy k8s-hpa k8s-job k8s-cronjob k8s-netpol
k8s-sa k8s-role k8s-rb k8s-c-role k8s-crb k8s-crd k8s-quota k8s-limits k8s-psp k8s-user k8s-group`

## Licensing

The package is "license: Varies": each collection keeps its owner's terms (AWS Architecture
Icons, Google Cloud and Azure icon terms, Kubernetes icons CC BY 4.0, Isoflow's own set).
compose writes an `Icons: ...` credit line into every diagram listing the collections used; do
not remove it.
