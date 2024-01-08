# MSDP Setup

## Preparations for Terraform (locally)

Before starting it is recommeded to have [ionosctl](https://github.com/ionos-cloud/ionosctl#getting-started) running on your machine.

You also need to make sure that the user you plan to use for terraforming is either a contract owner, an administrator or a users with the Manage Dataplatform permission (as documented [here](https://docs.ionos.com/cloud/managed-services/managed-stackable/how-tos/initial-cluster-setup)).

Then run `ionosctl login` to login with your credentials.

Now we need to set two environment variables. The variable `TF_VAR_cluster_description` lets Terraform know how the file is called in which we stored our cluster configurations. 

```shell
export TF_VAR_cluster_description=cluster-test.yaml
```

The variable `TF_VAR_ionos_token` should contain our token for the authentication against the IONOS API. To retrieve a token we can run `ionosctl token generate`. This command will retrieve the token and directly store it in the environment variable:

```shell
export TF_VAR_ionos_token=$(ionosctl token generate)
```

> **Info:** If you plan to run Terraform in a pipeline instead of running it locally you would store the variales `TF_VAR_cluster_description` and `TF_VAR_ionos_token` in your Gitlab or GitHub variables in your repository.

## Run Terraform (locally)

Before running the Terraform command you need to navigate to the `terraform` folder in your local repository.

```shell
cd terraform
```

Then run your typical Terraform commands:

```shell
terraform init
```

```shell
terraform validate
```

```shell
terraform plan
```

```shell
terraform apply
```

For destroying your cluster again use this command:

```shell
terraform destroy
```

> **Info:** You can run the same commands in the same order in your Gitlab pipeline or GitHub action and maybe separate them into different stages / jobs.

### Other ways to manage your MSDP clusters

- As an <ins>**alternative**</ins> to creating a cluster via Terraform this would be the necessary steps to create one with [ionosctl](https://docs.ionos.com/cli-ionosctl/subcommands/managed-stackable-data-platform):
  ```shell
  ionosctl login
  ```
  ```shell
  ionosctl datacenter create \
    --name MSDP_TEST \
    --location de/fra
  ```
  ```shell
  ionosctl dataplatform cluster create \
    --name MSDP_TEST \
    --version 23.11 \
    --maintenance-day Monday \
    --maintenance-time 16:30:59 \
    --datacenter-id <your-datacenter-id>
  ```
  ```shell
  ionosctl dataplatform nodepool create \
    --name MSDP_TEST \
    --node-count 3 \
    --cores 4 \
    --ram 8192 \
    --storage-size 100 \
    --storage-type SSD \
    --cluster-id <your-cluster-id>
  ```
  ```shell
  ionosctl dataplatform cluster kubeconfig \
    --output json \
    --cluster-id <your-cluster-id>
  ```
  To store the kubeconfig directly to a file you could do something like this:
  ```shell
  ionosctl dataplatform cluster kubeconfig \
    --output json \
    --cluster-id <your-cluster-id> \
    > kubeconfig.json
  ```
  These are the steps to destroy everything again:
  ```shell
  ionosctl dataplatform nodepool delete \
    --cluster-id <your-cluster-id> \
    --nodepool-id <your-nodepool-id>
  ```
  ```shell
  ionosctl dataplatform cluster delete \
    --cluster-id <your-cluster-id>
  ```
  ```shell
  ionosctl datacenter delete \
    --datacenter-id <your-datacenter-id>
  ```
- Another option would be to leverage the MSDP [OpenAPI specification](https://api.ionos.com/docs/dataplatform/v1/) - for example with the API client of your choice ([Postman](https://www.postman.com/), [Insomnia](https://github.com/Kong/insomnia) or other).

## Accessing the MSDP cluster

After following the steps for Terraform above you should find a `kubeconfig.yaml` file in the `terraform` folder of your local respository.

> Letting Terraform write a kubeconfig file to your local machine poses a potential security risk. Please use with caution.

Tools like [*kubectl*](https://kubernetes.io/docs/tasks/tools/), [*k9s*](https://github.com/derailed/k9s), [*helm*](https://helm.sh/) and others need to work in the correct context to address the correct Kubernetes cluster. An easy way to set this context is to define the environment variable `KUBECONFIG` and let it point to the `kubeconfig.yaml`.

```shell
export KUBECONFIG=${PWD}/terraform/kubeconfig.yaml
```

You can validate if you can access your MSDP cluster by starting `k9s` or by doing something trivial like listing the nodes of the cluster:

```shell
kubectl get nodes
```

## Prerequisites

For the prerequisites we are installing a Postgres database using a helm chart.

```shell
helm install pg-superset -f prerequisites/pg-superset.yaml oci://registry-1.docker.io/bitnamicharts/postgresql
```

> As soon as MSDP allows for a LAN connection to be defined during nodepool creation this should be replaced with a Managed Postgres available through the IONOS DBaaS offerings.

## Example deployment

To perform an example deployment using the Superset operator we can simply pass the custom resource like so:

```shell
kubectl apply -f resources/superset.yaml
```

To visit the Superset UI simply run `stackablectl stacklet list` to get the correct endpoint. For more information on stackablectl - a Stackable-native command-line tool - visit [this GitHub repository](https://github.com/stackabletech/stackablectl).

> To find resource blueprints please visit either the [official documentation](https://docs.stackable.tech/home/stable/operators/) or the [Stackable GitHub repositories](https://github.com/stackabletech). Please make sure to use resources for the **correct Stackable release version** - the version is defined in the Terraform configuration file.

### Tidying up

This command will delete the Kubernetes secret and the SupersetCluster resource which will then trigger the operator to remove the Superset deployment.

```shell
kubectl delete -f resources/superset.yaml
```

To delete the Postgres and its PVC use the following two commands:

```shell
helm delete pg-superset
```
> <ins>**Use with caution!**</ins> This deletes all PVCs on the cluster.

```shell
kubectl delete pvc --all
```

## Using stackablectl demos on MSDP clusters

[stackablectl](https://github.com/stackabletech/stackablectl) allows for complete demos with end-to-end dataflows to be installed with a single command.

As stackablectl is meant to work with vanilla Kubernetes clusters (that do not have the Stackable distribution and its operators per-installed) we need to use the flag `--additional-releases-file` to skip the operator installation.

This is how you would install the [nifi-kafka-druid-water-level-data](https://docs.stackable.tech/home/stable/demos/nifi-kafka-druid-water-level-data) demo:

```shell
stackablectl --release-file stackablectl/skip-operator-installation.yaml demo install nifi-kafka-druid-water-level-data
```

We can now monitor the demo deployments with `k9s`. As soon as all pods are running we can get the endpoints and connect to the tools via:

```shell
stackableclt stacklet list
```

> You can find more demos in the [official documentation](https://docs.stackable.tech/home/stable/demos/).

### Tidying up

As there is a lot to tidy up after installing a demo it's best to use a little script to help us.

> <ins>**Use with caution!**</ins> This basically resets your cluster entirely.

```shell
./stackablectl/cleanup-bruteforce.sh
```

Maybe you need to make the script executable first:

```shell
chmod u+x stackablectl/cleanup-bruteforce.sh
```