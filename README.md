# dtx-terraform

## Background

Infrastructure as code based on the automation tool [Terraform](https://www.terraform.io/). The wrapper [Terragrunt](https://terragrunt.gruntwork.io/) executes Terraform and provides several features to reduce repitition in backend configuration and allow sharing of outputs between stacks.

## Terraform Resources

Any resource controlled by Terraform can be updated manually via other means. However, the next time Terraform applies the module to the resources, Terraform will recognize the changes and replace them with whatever values the module is configured for.

As such, all changes to Terraform resources should only be made through the Terraform modules.

## Remote State Backend

Terraform requires a state file to know what objects were created and what state they should be in. By default it stores that data locally. This, of course, doesn't work for a team of users. Using a remote backend allows all users to access the data at any time. The only issue is ensuring that two teammates don't try to update the state stack/state file at the same time.

Some of Terraform's backends support a locking mechanism. Unfortunately, none of the backends that work with Oracle support the locking mechanism. *Thus anyone updating Terraform stacks MUST coordinate with other teammates.*

Terragrunt manages the remote state backend configuration from a single location. It will place it in location needed by Terraform at runtime. View the `remote_state` block of the `[live/terragrunt.hcl](live/terragrunt.hcl)` file.

This Terraform configuration uses the Terraform AWS S3 backend and OCI's S3-compatible interface to the Object Storage bucket. This is the suggested configuration from OCI's documentation. Any user will need their [Customer Secret Keys](https://docs.oracle.com/en-us/iaas/Content/Identity/Tasks/managingcredentials.htm#Working2) configured using the AWS environment variables of `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`, the shared credentials file `~/.aws/credentials` or the shared configuration file `~/.aws/config`.

## Important IDs

### Tenancy

* ID - `ocid1.tenancy.oc1..aaaaaaaan3et4ej5l24sbsejheik5bv4fjradz7xgqtr5didj5accbdctmbq`
* Namespace - `axnfm4jb3i73`

### Compartments

* DTX_PaaS - `ocid1.compartment.oc1..aaaaaaaac7cwwdhbssjfcg6tjx47s3gaoqumovoxahcrmmgaryegybvourla`
  * DTX_PaaS-Shared - `ocid1.compartment.oc1..aaaaaaaaelhj7c2mf6thajka6uhgccy6ps7j5a2nssvzrvpul3ypaodavflq`
  * DTX_PaaS-Dev - `ocid1.compartment.oc1..aaaaaaaaimjp3jzwblxkr2ptywfbb6zqt7k4ykvluue6g37gqiedf6yd5sqq`
  * DTX_PaaS-Test - `ocid1.compartment.oc1..aaaaaaaaee3wnhqiddvsxbly63hxdk6vgzcs2spvd2d6krnwp6f7tg77g5va`
  * DTX_PaaS-Sandbox - `ocid1.compartment.oc1..aaaaaaaabavsmgb2to2nczlztwy5w3lcopfajpf5hvum4tcz2i2bzt7pd77a`
  * DTX_PaaS-Prod - `ocid1.compartment.oc1..aaaaaaaabbdhkjwvax2aipzcur3vcuaedudswwdualjwykimeensgjzbht7q`
