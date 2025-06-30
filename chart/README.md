# Nextcloud Helm Chart

This Helm chart deploys a scalable and highly available Nextcloud instance on Kubernetes.

## Overview

This chart deploys a complete Nextcloud environment, including a custom Nextcloud PHP-FPM image, Nginx reverse proxy, and dependencies for caching, database, and object storage.

### Architecture 

### Features

-   **High Availability**: Supports multiple replicas for Nextcloud, Nginx, and a clustered PostgreSQL database via CloudNativePG.
-   **Scalable Storage**: Integrates with any S3-compatible object storage.
-   **Optimized Performance**: Uses Redis for caching/session management and includes optimized Nginx and PHP-FPM configurations.
-   **Automated TLS**: Manages SSL certificates with cert-manager.
-   **Collabora Online**: Optional integration for in-browser office document editing.

## Prerequisites

-   **Kubernetes Cluster**: v1.20+
-   **Operators**: [cert-manager](https://cert-manager.io/), [CloudNativePG](https://cloudnative-pg.io/).
-   **Ingress Controller**: HAProxy, NGINX, or similar.
-   **S3-compatible Storage**: MinIO, AWS S3, etc.

> [!NOTE]
> **StorageClass**: If want multiple replicas of nextcloud that is not located on the same kubernetes worker. You need a storageclass that supports RWX with multiple writers. For example
> - CephFS (rook)
> - NFS

## Installation

1.  **Clone Repository**:
    ```bash
    # Clone the parent repository
    git clone <repository-url>
    cd nextcloud-k8s
    ```

2.  **Create Namespace**:
    ```bash
    kubectl apply -f namespace.yaml
    ```

3.  **Configure Secrets**:
    This chart uses sealed secrets for managing sensitive data.
    ```bash
    # 1. Edit unsealed secrets in secrets/unsealed/
    # 2. Seal them
    ./seal-secrets.sh
    # 3. Apply the sealed secrets
    ./reapply-sealed-secrets.sh
    ```

4.  **Deploy Chart**:
    ```bash
    # Review and customize chart/values.yaml as needed
    helm install nextcloud ./chart -n nextcloud
    ```

5.  **Access Nextcloud**:
    Access your instance at the domain specified in `values.yaml` (default: `nextcloud.local`).

## Configuration

Configuration is managed through `chart/values.yaml` and a Kubernetes secret.

### Helm Values (`values.yaml`)

- `nextcloudDomain`: The primary domain for Nextcloud.
- `nextcloudImageTag`, `nginxImageTag`: Docker image tags for the services.
- `nextcloud.replicaCount`: Set to `1` for single-node, `>1` for HA.
- `cloudnativepg.enabled`, `redis.enabled`, `collabora.enabled`: Toggle dependencies.
- `cloudnativepg.cluster`: Set to `true` for a 3-node database cluster.

### Environment Variables (`nextcloud-env` Secret)

Create a `Secret` named `nextcloud-env` in the `nextcloud` namespace containing credentials for external services. Refer to `secrets/unsealed/nextcloud-environment.yaml` in the parent directory for the required keys.

- **S3 Storage**: `OBJECTSTORE_HOST`, `OBJECTSTORE_PORT`, `OBJECTSTORE_BUCKET`, `OBJECTSTORE_KEY`, `OBJECTSTORE_SECRET`.
- **Redis**: `REDIS_HOST`, `REDIS_PORT`, `REDIS_PASSWORD`.
- **Nextcloud Admin**: `NEXTCLOUD_ADMIN_USER`, `NEXTCLOUD_ADMIN_PASSWORD`.

##### Example config
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: nextcloud-env
type: Opaque
stringData:
  OBJECTSTORE_HOST: 192.168.1.5
  OBJECTSTORE_PORT: "9000"
  OBJECTSTORE_BUCKET: nextcloud
  OBJECTSTORE_KEY: nextcloud
  OBJECTSTORE_SECRET: nextcloud123
  REDIS_HOST: redis
  REDIS_PORT: "6379"
  REDIS_PASSWORD: nextcloud123
  NEXTCLOUD_ADMIN_USER: admin
  NEXTCLOUD_ADMIN_PASSWORD: changeme
  # Dont change this
  NEXTCLOUD_DIRECTORY: /var/www/html
  DATA_DIRECTORY: /mnt/ncdata
```

## Maintenance

### Scaling
```bash
# Scale Nextcloud pods
helm upgrade nextcloud ./chart -n nextcloud --set nextcloud.replicaCount=3
```

### Database Management
```bash
# Check cluster status
kubectl get cluster -n nextcloud

# Access PostgreSQL CLI
kubectl exec -it nextcloud-1 -n nextcloud -- psql -U nextcloud
```

> [!TIP]
> If you are using cloudnative-pg add this part to your nextcloud config.php manually
> https://docs.nextcloud.com/server/latest/admin_manual/configuration_database/replication.html
> ```
> 'dbreplica' => [
>    [
>      'user' => 'nextcloud',
>      'password' => '<your-database-password>',
>      'host' => 'db-ro.nextcloud.svc.cluster.local',
>      'dbname' => 'db'
>    ],
>  ],
> ```

## Troubleshooting

- **Installation Fails**: Check logs of the `check-db-ready` and `check-s3-access` init containers in the Nextcloud pod.
- **Permission Errors**: Set `rootNeededForDirectoryFix: true` in `values.yaml` if the PVC has restrictive permissions.
- **Database Connection**: Check the status of the CloudNativePG cluster: `kubectl get cluster nextcloud -n nextcloud -o yaml`.
- **Redis Connection**: Test connectivity with `kubectl exec -it deployment/redis -n nextcloud -- redis-cli ping`.