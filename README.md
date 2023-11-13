# MSDP Setup

## Preparations for Terraform (locally)

Before starting it is recommeded to have [ionosctl](https://github.com/ionos-cloud/ionosctl#getting-started) running on your machine.

You also need to make sure that the user you plan to use for terraforming is either a contract owner, an administrator or a users with the Manage Dataplatform permission (as documented [here](https://docs.ionos.com/cloud/managed-services/managed-stackable/how-tos/initial-cluster-setup)).

Then run `ionosctl login` to login with your credentials and `ionosctl token generate` to retrieve a token.

Now we need to set two environment variables. The variable `TF_VAR_cluster_description` let's Terraform know how the file is called in which we stored our cluster configurations. 

```shell
export TF_VAR_cluster_description=cluster-test.yaml
```

The variable `TF_VAR_ionos_token` should contain our token for the authentication against the IONOS API.

```shell
export TF_VAR_ionos_token=<yourToken>
```

>**Info:** If you plan to run Terraform in a pipeline instead of locally you would store the variales `TF_VAR_cluster_description` and `TF_VAR_ionos_token` in your Gitlab or Github variables in your repo.

## Run Terraform (locally)

Before running the Terraform command you need to navigate to the `terraform` folder.

```shell
cd terraform
```

Then run your typical Terraform commands.

```shell
terraform init
terraform validate
terraform plan
terraform apply
```

For destroying your cluster again use this command:

```shell
terraform destroy
```

>**Info:** You can run the same commands in the same order in your Gitlab pipeline or Github action and maybe separate them into different stages / jobs.

### Other ways to manage your MSDP clusters

- [ionosctl](https://docs.ionos.com/cli-ionosctl/subcommands/managed-stackable-data-platform)
- [OpenAPI specification](https://api.ionos.com/docs/dataplatform/v1/)

## Accessing the MSDP cluster

After following the steps above you should find a `kubeconfig.yaml` in the `terraform` folder of your local respository.

> Letting Terraform write a kubeconfig file to your local machine poses a potential security risk. Please use with caution.

Tools like [*kubectl*](https://kubernetes.io/docs/tasks/tools/), [*k9s*](https://github.com/derailed/k9s), [*helm*](https://helm.sh/) and others need to work in the correct context to address the correct Kubernetes cluster. An easy way to set this context is to define the environment variable `$KUBECONFIG` and let it point to the `kubeconfig.yaml`.

```shell
export KUBECONFIG=${PWD}/terraform/kubeconfig.yaml
```

You can validate if you can access your MSDP cluster by starting `k9s` or by doing something simple like listing the nodes of the cluster:

```shell
kubectl get nodes
```

## Prerequisites

For the prerequisites we are installing a Postgres database using a helm chart.

```shell
helm install pg-superset -f prerequisites/pg-superset.yaml oci://registry-1.docker.io/bitnamicharts/postgresql
```

## Example deployment

To perform an example deployment using the Superset operator we can simply pass the custom resources like so:

```shell
kubectl apply -f resources/superset.yaml
```

To visit the Superset UI simply run `stackablectl services list` to get the correct endpoint. For more infos on stackablectl visit https://github.com/stackabletech/stackablectl.

## Tidying up

```shell
kubectl delete -f resources/superset.yaml
```

```shell
helm delete pg-superset
```

```shell
kubectl delete pvc --all
```