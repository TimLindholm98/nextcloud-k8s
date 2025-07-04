# Nextcloud on Kubernetes

Scalable Nextcloud deployment for Kubernetes

## Overview

This project provides a simplified solution for deploying Nextcloud on Kubernetes. This does some things different then the "offical" image.

**Its focus is to make it easy to**
  - Deploy ✅
  - Install ✅
  - Scale ✅
  
**Avoiding extra complexity by doing to much:**
  - This dosent manage the nextcloud installation after its installed, nextcloud-k8s manages the pods not the application inside.
  - Create a fully automatic seemless upgrade experince, mostly because we dont handle the application inside the pods. This could change with contributions.

> [!NOTE]
> If there is a good way to upgrade in a k8s native way we could impliment it.
>
> But I would like to avoid creating extra complexity, nextcloud is not really built with kuberntetes in mind so all the soloutions i can think are to complex for not that much improvment

## How to uppgrade

1. Check php version compatiblity.
2. Use the nextcloud updater in the GUI or the `occ` command as you would in a manual install.

## Prerequisites

-   **Operators**: 
    -   [CloudNativePG](https://cloudnative-pg.io/). *Required*
    -   [cert-manager](https://cert-manager.io/) *Optional, but higly recomended*
    -   [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) *Optional*
-   **Ingress Controller**: HAProxy, NGINX, or similar are recomended if you are going to use collabora.
-   **S3-compatible Storage**: 
    -   Tested with MinIO.

> [!IMPORTANT]
> **StorageClass**: If you want multiple replicas of nextcloud that is not located on the same kubernetes worker. You need a storageclass that supports RWX with multiple writers. For example
> - CephFS (rook)
> - NFS

## 📖 Documentation

- **[Helm Chart Documentation](chart/README.md)** - Details about the helm chart

- **[Docker Image Documentation](image/README.md)** - Details about the custom Docker image.


## TODO

- [ ] CronJob
