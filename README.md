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

For simplicity we're going to pass new parameters for the values.yaml at runtime, normally you'd customise a copy of the values.yaml for your deployed environment.

```bash
az group create -n conaks -l eastus
DEP=$(az deployment group create -g conaks -f .\main.bicep)

# Get the Aks cluster name
AksName=$(cho $DEP | jq -r '.properties.outputs.AksName.value')

# Get the Container Registry Resource Id
AcrId=$(cho $DEP | jq -r '.properties.outputs.acrResourceId.value')

# Create a service principal with the Reader role on your registry
SP=$(az ad sp create-for-rbac --name gb-connaisseur --role Reader --scopes $AcrId)
APPID=$(echo $SP | jq -r '.appId')
APPPW=$(echo $SP | jq -r '.password')

az aks get-credentials -n $AksName -g conaks

helm repo add connaisseur https://sse-secure-systems.github.io/connaisseur/charts;
helm repo update;
helm upgrade --install connaisseur connaisseur/helm --atomic --create-namespace --namespace connaisseur --set validators[2].auth.username=$APPID,validators[2].auth.password=$APPPW,validators[2].is_acr=True;

kubectl get all -n connaisseur
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
