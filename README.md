# Creating a Kubernetes Dev Cluster

> For information on setting up a production Kubernetes cluster on Azure please see [Azure Kubernetes Service (AKS)](https://azure.microsoft.com/en-us/services/kubernetes-service/)

This script sets up a single-node Kubernetes development cluster on an Azure VM. While this is not intended to be a production cluster ([AKS](https://azure.microsoft.com/en-us/services/kubernetes-service/) is a more complete solution). The approach is similar to using [minkube](https://minikube.sigs.k8s.io/docs/) or [kind](https://kind.sigs.k8s.io/docs/) but it's a complete Kubernetes deployment using [kubeadm](https://kubernetes.io/docs/tasks/tools/).

We have found that the `kubeadm` approach helps engineers learn more about what is happening under the covers with Kubernetes and AKS and it's a great next step from `minikube` or `kind`. It is also a great way for developers to debug applications as they have full access to Kubernetes and can quickly experiment and debug. There are also potential cost savings as a developer can run a dedicated Kubernetes "cluster" on a single VM.

> The scripts and instructions will work with other VM hosts with minimal changes

## More Information

- Explanation of the steps in this [script](https://github.com/retaildevcrews/k8s-quickstart/tree/main/02-Dev-Cluster-Setup)
- Kubernetes [best practices](https://kubernetes.io/docs/setup/best-practices/)
- Bootstrapping clusters with [kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/)
- Azure Kubernetes Service [(AKS)](https://azure.microsoft.com/en-us/services/kubernetes-service/)

## Prerequisites

- Bash or Windows cmd shell
- Azure CLI ([download](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest))

> Visual Studio Code Remote is [highly recommended](https://code.visualstudio.com/docs/remote/ssh)

## Host VM Requirements

- tested on `Ubuntu 18.04 LTS`
- minimum 2 cores with 2 GB RAM

## Setup

### Login to Azure

```bash

az account list -o table

# login to Azure (if necessary)
az login

# select subscription (if necesary)
az account set -s YourSubscriptionName

```

### Installation (bash)

> From a bash terminal

```bash

# change your resource group name and location if desired
export AKDC_LOC=centralus
export AKDC_RG=akdc

# Create a resource group
az group create -l $AKDC_LOC -n $AKDC_RG

# download setup script
# replace user name
curl https://raw.githubusercontent.com/microsoft/kubernetes-developer-cluster-kubeadm/main/scripts/auto.sh | sed s/ME=akdc/ME=$USER/ > akdc.sh

# create an Ubuntu VM and install k8s
# save IP address into the AKDC_IP env var

export AKDC_IP=$(az vm create \
  -g $AKDC_RG \
  --admin-username $USER \
  -n akdc \
  --size standard_d2s_v3 \
  --nsg-rule SSH \
  --image Canonical:UbuntuServer:18.04-LTS:latest \
  --os-disk-size-gb 128 \
  --generate-ssh-keys \
  --query publicIpAddress -o tsv \
  --custom-data akdc.sh)

rm akdc.sh

echo $AKDC_IP

# (optional) open NodePort range on NSG
az network nsg rule create -g $AKDC_RG \
--nsg-name akdcNSG --access allow \
--description "AKDC Ports" \
--destination-port-ranges 30000-32767 \
--protocol tcp \
-n AkdcPorts --priority 1200

# SSH into the VM
ssh ${AKDC_IP}

```

### Installation (Windows cmd)

> From a Windows cmd prompt

```bash

# change your resource group name and location if desired
set AKDC_LOC=centralus
set AKDC_RG=akdc

# Create a resource group
az group create -l %AKDC_LOC% -n %AKDC_RG%

# download setup script
curl https://raw.githubusercontent.com/microsoft/kubernetes-developer-cluster-kubeadm/main/scripts/auto.sh > akdc.txt

# replace user name
powershell -Command "(gc akdc.txt) -replace 'ME=akdc', 'ME=%USERNAME%' | Out-File -encoding ASCII akdc.sh"

# create an Ubuntu VM and install k8s
# save IP address into the AKDC_IP env var

for /f %f in (' ^
  az vm create ^
  -g %AKDC_RG% ^
  --admin-username %USERNAME% ^
  -n akdc ^
  --size standard_d2s_v3 ^
  --nsg-rule SSH ^
  --image Canonical:UbuntuServer:18.04-LTS:latest ^
  --os-disk-size-gb 128 ^
  --generate-ssh-keys ^
  --query publicIpAddress -o tsv ^
  --custom-data akdc.sh') ^
do set AKDC_IP=%f

del akdc.txt
del akdc.sh

echo %AKDC_IP%

# (optional) open NodePort range on NSG
az network nsg rule create -g %AKDC_RG% ^
--nsg-name akdcNSG --access allow ^
--description "AKDC Ports" ^
--destination-port-ranges 30000-32767 ^
--protocol tcp ^
-n AkdcPorts --priority 1200

ssh %AKDC_IP%

```

## Validation

> From a bash shell in the VM via SSH

The first time you SSH into the VM, you might get the below error - it is safe to ignore.

- Command 'kubectl' not found, but can be installed with:
- sudo snap install kubectl

```bash

# this will tell you when the user data script is done
tail -f status

# (optional) install oh-my-bash kubectl aliases
sed -i "s/^plugins=($/plugins=(\n  kubectl/g" .bashrc
source .bashrc

# make sure everything is up to date
sudo apt update
sudo apt dist-upgrade -y

# your single-node k8s dev cluster is now ready
kubectl get all --all-namespaces

```

## Reset cluster to start over

You can usually reset your k8s cluster to a clean install with `kubeadm reset`  If reset fails, you will need to delete the VM and create a new one.

> From a bash shell in the VM via SSH

```bash

curl https://raw.githubusercontent.com/microsoft/kubernetes-developer-cluster-kubeadm/main/scripts/reset.sh > reset.sh
chmod +x reset.sh

# reset your cluster
./reset.sh

```

## Contributing

This project welcomes contributions and suggestions. Most contributions require you to agree to a Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us the rights to use your contribution. For details, visit [Microsoft Contributor License Agreement](https://cla.opensource.microsoft.com).

When you submit a pull request, a CLA bot will automatically determine whether you need to provide a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks

This project may contain trademarks or logos for projects, products, or services.

Authorized use of Microsoft trademarks or logos is subject to and must follow [Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).

Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.

Any use of third-party trademarks or logos are subject to those third-party's policies.
