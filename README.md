# Nextcloud on Kubernetes

Scalable Nextcloud deployment for Kubernetes

## Overview

This project provides a simplified solution for deploying Nextcloud on Kubernetes. This does some things different then the "offical" image.

**Its focus is to make it easy to**
  - Deploy ✅
  - Install ✅
  - Scale ✅
  
**Create extra complexity to:**
  - Manage the nextcloud installation, nextcloud-k8s manages the pods not the application inside.
  - Create a fully automatic seemless upgrade experince, mostly because we dont handle the application inside the pods. This could change with contributions.

> [!NOTE]
> If there is a good way to upgrade in a k8s native way we could impliment it.
>
> But I would like to avoid creating extra complexity, nextcloud is not really built with kuberntetes in mind so all the soloutions i can think are to complex for not that much improvment

## How to uppgrade

1. Check php version compatiblity.
2. Use the nextcloud updater in the GUI or the `occ` command as you would in a manual install.

## 📖 Documentation

- **[Helm Chart Documentation](chart/README.md)** - Complete guide for deploying Nextcloud on Kubernetes using Helm

- **[Docker Image Documentation](image/README.md)** - Details about the custom Docker images.
