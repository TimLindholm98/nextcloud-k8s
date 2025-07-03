## Quick Installation

> [!NOTE]
> You already need a S3 storage area for this example to work.

1.  **Clone Repository**:
    ```bash
    # Clone the parent repository
    git clone <repository-url>
    cd nextcloud-k8s
    ```

2.  **Configure Secrets**:
    This chart uses sealed secrets for managing sensitive data.
    ```bash
    # 1. Create a secret in secrets/unsealed
    cat > secrets/unsealed/nextcloud-env.yaml << EOF
    apiVersion: v1
    kind: Secret
    metadata:
      name: nextcloud-env
      namespace: nextcloud
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
      NEXTCLOUD_DIRECTORY: /var/www/html
      DATA_DIRECTORY: /mnt/ncdata
    EOF
    # 2. Seal them
    ./seal-secrets.sh
    ```

3.  **Deploy Chart**:
    ```bash
    cd example

    helm dependency build
    
    helm install nextcloud ./ \
        -n nextcloud \
        --create-namespace \
        -f ../chart/values.yaml \
        -f nextcloud.yaml
    ```

3. **Install nextcloud**
```bash
   kubectl exec -n nextcloud -ti nextcloud-678fd86666-x9tvt -- /install.sh
```