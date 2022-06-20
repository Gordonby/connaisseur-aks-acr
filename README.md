# connaisseur-aks-acr
A sample of using connaisseur with AKS / ACR

`status = in-progress`

## Sample Objective

To deploy a complete sample of [connaisseur](https://github.com/sse-secure-systems/connaisseur) for performing container image signature verification on the Azure Kubernetes Service and Azure Container Registry. All infrastructure is deployed using Bicep from. 

## Notable components

## Connaisseur

Connaisseur intercepts Kubernetes resource creation / update requests sent to the cluster. It identifies all container images and verifies their signatures against pre-configured public keys. Based on the result, it either accepts or denies those requests.
 
### ACR

Provides hosting of container images where they can be [scanned by Microsoft Defender](https://docs.microsoft.com/azure/defender-for-cloud/defender-for-containers-introduction?tabs=defender-for-container-arch-aks#scanning-images-in-acr-registries) before being used in Kubernetes.

### AKS

[AKS Construction](https://github.com/Azure/Aks-Construction) is being leveraged to deploy a secure cluster in a simple way.

## The bicep


## Lets deploy it!

The Azure CLI is the only prerequisite. If you deploy from the Azure CloudShell then this makes the process even simpler.

```bash

```

## The Result

## Repo Notes

This repo uses git submodules. The following commands were run to clone the respective repositories at a point in time.
This was done rather than forking as
- This project will not be contributing back to the Petclinic sample
- Submodules captures the repo at a point in time, which is good for our sample. We can fetch latest and test as this sample is periodically reviewed.

```bash
git submodule add https://github.com/Azure/AKS-Construction.git aks-construction
git submodule add https://github.com/sse-secure-systems/connaisseur.git connaisseur
```
