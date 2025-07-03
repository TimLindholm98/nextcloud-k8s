# Nextcloud Helm Chart

This Helm chart deploys a scalable and highly available Nextcloud instance on Kubernetes.

## Overview

This chart deploys a complete Nextcloud environment, including a custom Nextcloud PHP-FPM image, Nginx reverse proxy, and dependencies for caching, database, and object storage.

### Helm Values (`values.yaml`)

- `nextcloudDomain`: The domain for Nextcloud.
- `nextcloudImageTag`, `nginxImageTag`: Docker image tags for the services.
- `nextcloud.replicaCount`: Set to `1` for single-node, `>1` for Multiple replicas.
- `cloudnativepg.enabled` Disable if you want to configure your own.
- `cloudnativepg.cluster`: Set to `true` for a 3-node database cluster.
- `redis.enabled` Disable if you want to deploy your own instance

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
  # If you have disabled cloudnativepg you need to configure these manually
  # POSTGRES_HOST
  # POSTGRES_PORT
  # POSTGRES_USER
  # POSTGRES_DB
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
> If you are using cloudnative-pg and a cluster add this part to your nextcloud config.php manually
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


## Values

The following table lists the configurable parameters of the Nextcloud chart and their default values:

### Core Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `nextcloudDomain` | The domain name for Nextcloud | `&nextcloudDomain nextcloud.local` |
| `nextcloudImageTag` | Docker image tag for Nextcloud PHP-FPM | `20250629-1552` |
| `nginxImageTag` | Docker image tag for Nginx reverse proxy | `20250629-1552` |
| `nextcloud.trustedDomains` | List of trusted domains for Nextcloud | `[*nextcloud.local, localhost]` |

### Nextcloud Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `nextcloud.trustedProxies` | List of trusted proxy networks | `[10.0.0.0/24]` |
| `nextcloud.replicaCount` | Number of Nextcloud pod replicas | `1` |
| `nextcloud.storage.storageClass` | Storage class for Nextcloud persistent volume | `""` |
| `nextcloud.storage.size` | Size of Nextcloud persistent volume | `10Gi` |
| `nextcloud.resources.requests.cpu` | CPU request for Nextcloud pods | `300m` |
| `nextcloud.resources.requests.memory` | Memory request for Nextcloud pods | `512Mi` |
| `nextcloud.resources.limits.cpu` | CPU limit for Nextcloud pods | `1500m` |
| `nextcloud.resources.limits.memory` | Memory limit for Nextcloud pods | `1Gi` |

### Ingress Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `nextcloud.ingress.enabled` | Enable ingress for Nextcloud | `true` |
| `nextcloud.ingress.annotations` | Annotations for the ingress resource | `{}` |
| `nextcloud.ingress.tlsSecretName` | Name of the TLS secret for HTTPS | `""` |

### Database Configuration (CloudNativePG)

| Parameter | Description | Default |
|-----------|-------------|---------|
| `cloudnativepg.enabled` | Enable CloudNativePG database | `true` |
| `cloudnativepg.cluster` | Enable 3-node PostgreSQL cluster | `true` |
| `cloudnativepg.databaseName` | Database name | `db` |
| `cloudnativepg.databaseUser` | Database username | `nextcloud` |
| `cloudnativepg.storage.storageClass` | Storage class for database | `database` |
| `cloudnativepg.storage.size` | Size of database persistent volume | `10Gi` |

### Redis Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `redis.enabled` | Enable Redis deployment | `true` |
| `redis.persistence` | Enable persistence for Redis | `false` |

### Example Values Override

```yaml
# Custom domain and image tags
nextcloudDomain: my-nextcloud.example.com
nextcloudImageTag: latest
nginxImageTag: latest

# Scale to multiple replicas
nextcloud:
  replicaCount: 3
  trustedDomains:
    - my-nextcloud.example.com
    - internal.example.com
  trustedProxies:
    - 10.0.0.0/8
    - 172.16.0.0/12
  
  # Custom storage configuration
  storage:
    storageClass: fast-ssd
    size: 50Gi
  
  # Resource limits for production
  resources:
    requests:
      cpu: "500m"
      memory: "1Gi"
    limits:
      cpu: "2000m"
      memory: "2Gi"
  
  # Ingress with TLS
  ingress:
    enabled: true
    annotations:
      cert-manager.io/cluster-issuer: letsencrypt-prod
      nginx.ingress.kubernetes.io/proxy-body-size: "0"
    tlsSecretName: nextcloud-tls

# Database configuration
cloudnativepg:
  enabled: true
  cluster: true
  storage:
    storageClass: database-ssd
    size: 100Gi

# Redis configuration
redis:
  enabled: true
  persistence: true
```

> [!NOTE]
> When scaling `nextcloud.replicaCount` beyond 1, Redis is required for session handling. Ensure Redis is enabled and properly configured via the `nextcloud-env` secret.

> [!IMPORTANT]
> External service credentials (S3, Redis) must be configured in the `nextcloud-env` secret as described in the Environment Variables section above.