# connaisseur-aks-acr

A sample of using connaisseur with AKS / ACR. A massive thanks to Kevin Harris for helping me with this sample 😛

`repo status = works if you use the localvalues.yaml route`

## Sample Objective

To deploy a complete sample of [connaisseur](https://github.com/sse-secure-systems/connaisseur) for performing container image signature verification on the Azure Kubernetes Service and Azure Container Registry. All infrastructure is deployed using Bicep. 

## Notable components

## Connaisseur

Connaisseur intercepts Kubernetes resource creation / update requests sent to the cluster. It identifies all container images and verifies their signatures against pre-configured public keys. Based on the result, it either accepts or denies those requests.
 
### ACR

Provides hosting of container images where they can be [scanned by Microsoft Defender](https://docs.microsoft.com/azure/defender-for-cloud/defender-for-containers-introduction?tabs=defender-for-container-arch-aks#scanning-images-in-acr-registries) before being used in Kubernetes.

### AKS

[AKS Construction](https://github.com/Azure/Aks-Construction) is being leveraged to deploy a secure cluster in a simple way, with an ACR already enabled for Docker Content Trust.

## The bicep


## Lets deploy it!

The Azure CLI is the only prerequisite. If you deploy from the Azure CloudShell then this makes the process even simpler.

For simplicity we're going to pass new parameters for the values.yaml at runtime, normally you'd customise a copy of the values.yaml for your deployed environment.

```bash
rg=conaks

az group create -n $rg -l eastus
DEP=$(az deployment group create -g conaks -f .\main.bicep)

# Get the Aks cluster name
AksName=$(echo $DEP | jq -r '.properties.outputs.aksName.value')

# Get the Container Registry variables ready
AcrId=$(echo $DEP | jq -r '.properties.outputs.acrResourceId.value')
AcrLoginServer=$(echo $DEP | jq -r '.properties.outputs.acrHostname.value')
AcrName=$(echo $DEP | jq -r '.properties.outputs.acrName.value')

# Create a service principal with the Reader role on your registry
SP=$(az ad sp create-for-rbac --name gb-connaisseur --role Reader --scopes $AcrId)
APPID=$(echo $SP | jq -r '.appId')
APPPW=$(echo $SP | jq -r '.password')

az aks get-credentials -n $AksName -g $rg

# Generate a signing key 
docker trust key generate root
```

Because of the level of configuration specific to your environment, it's recommended that you leverage your own values.yaml file.
For the sake of a quick sample this code passed all of the commands are passed during the install chart command.

### 1. Overriding parameters on chart install

```bash
#
helm upgrade --install connaisseur connaisseur/helm --atomic --create-namespace --namespace connaisseur --set validators[2].auth.username=$APPID,validators[2].auth.password=$APPPW,validators[2].is_acr=True;

kubectl get all -n connaisseur
```

### 2. Using a values.yaml

Copy the values.yaml from the Connaisseur repo and customised the default validators section like this, replacing the redacted values with the ones from the appropriate variables above;

```yml
  - name: default
    type: notaryv1
    host: REDACTED.azurecr.io
    trust_roots:
    - name: default
      key: |  # enter your public key below
        -----BEGIN PUBLIC KEY-----
        REDACTED
        -----END PUBLIC KEY-----
    auth:
      username: REDACTED
      password: REDACTED
    is_acr: true
```

Then install Connaisseur.

```bash
helm upgrade --install connaisseur connaisseur/helm --atomic --create-namespace --namespace connaisseur -f localvalues.yaml --debug;
```

## The Result

```bash
kubectl get po -n connaisseur
```

```text
NAME                                      READY   STATUS    RESTARTS   AGE
connaisseur-deployment-85d5c8b995-ghtcw   1/1     Running   0          74s
connaisseur-deployment-85d5c8b995-knzwd   1/1     Running   0          74s
connaisseur-deployment-85d5c8b995-tfj24   1/1     Running   0          74s
```

### Lets test it!

Firstly lets test with the image thats already in our ACR that hasn't been signed. We hope that this fails.

```bash
kubectl run docs-not-signed --image=$acrname.azurecr.io/azuredocs/azure-vote-front:v2

Error from server: admission webhook "connaisseur-svc.connaisseur.svc" denied the request: Unable to get timestamp trust data from default.
```

Ok, so that works great. Now lets push a signed image to the ACR.

First we'll need to give ourselves RBAC.

```bash
currentuser=$(az ad signed-in-user show --query id -o tsv)
az role assignment create --scope $acrId --role AcrImageSigner --assignee $currentuser
```

```bash
# Login to the ACR with Docker
token=$(az acr login -n $ACRNAME --expose-token)
ACRTOKEN=$(echo $TOKEN | jq -r ".accessToken")
LOGINSERVER=$(echo $TOKEN | jq -r ".loginServer")
echo $ACRTOKEN | docker login $LOGINSERVER -u 00000000-0000-0000-0000-000000000000 --password-stdin

docker pull $acrname.azurecr.io/azuredocs/azure-vote-front:v2

# Lets check the ImageId of the azuredocs/azure-vote-front:v2 image
docker images
imageId=09e5719a89a8

# Re-tag to v3
docker tag $imageId "$acrname.azurecr.io/azuredocs/azure-vote-front:v3"

# Push a signed image
docker push "$acrname.azurecr.io/azuredocs/azure-vote-front:v3" --disable-content-trust=false

# Test running the image in k8s
kubectl run docs-signed --image=$acrname.azurecr.io/azuredocs/azure-vote-front:v3

pod/docs-signed created
```


## Repo Notes

This repo uses git submodules. The following commands were run to clone the respective repositories at a point in time.
This was done rather than forking as
- This project will not be contributing back to the Petclinic sample
- Submodules captures the repo at a point in time, which is good for our sample. We can fetch latest and test as this sample is periodically reviewed.

```bash
git submodule add https://github.com/Azure/AKS-Construction.git aks-construction
git submodule add https://github.com/sse-secure-systems/connaisseur.git connaisseur
```

## Troubleshooting

### UPGRADE FAILED: another operation (install/upgrade/rollback) is in progress

```bash
# Check to see pending installs
helm history connaisseur -n connaisseur

# Rollback any pending installs
helm rollback connaisseur 1 -n connaisseur

# Check to see whats installed
helm list -n connaisseur

# Uninstall
helm uninstall connaisseur -n connaisseur
```

### Deployment is not ready: connaisseur/connaisseur-deployment. 0 out of 3 expected pods are ready

Sometimes the deployment can get stuck if the config is bad.

```bash
# Get pods
kubectl get po -n connaisseur

# View logs
kubectl logs <pod-name> -n connaisseur
```