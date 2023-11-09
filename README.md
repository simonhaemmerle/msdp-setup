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