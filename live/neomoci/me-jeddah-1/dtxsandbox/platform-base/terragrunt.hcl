locals {
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  env_vars    = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  approved_senders = [
    "do-not-reply-sandbox@mirrana.io"
  ]
}

terraform {
  source = "${get_parent_terragrunt_dir()}/../modules//platform-base"
}

include "root" {
  path = find_in_parent_folders()
}

dependency "vcn" {
  config_path = "../vcn"

  mock_outputs_allowed_terraform_commands = [
    "validate"
  ]
  mock_outputs = {
    id             = "fake-id"
    name           = "fake-name"
    compartment_id = "fake-compartment-id"
    subnets        = {
      subnet1 = {
        id   = "ABC"
        tier = "app"
        type = "private"
      }
    }
    bastion_nsg_id = "XXX"
  }
}

dependency "cluster" {
  config_path = "../oke-cluster"

  mock_outputs_allowed_terraform_commands = [
    "validate"
  ]
  mock_outputs = {
    id                      = "fake-id"
    name                    = "fake-name"
    compartment_id          = "fake-compartment-id"
    private_subnet_id       = "fake-private-subnet-id"
    network_security_groups = {
      workers = {
        id   = "ABC"
      }
    }
    ssh_public_key = "fake-ssh-key"
  }
}

dependencies {
  paths = [
    "../vcn",
    "../oke-cluster",
  ]
}

inputs = {
  region                = local.region_vars.locals.region
  compartment_id        = local.env_vars.locals.compartment_id
  shared_compartment_id = local.env_vars.locals.shared_compartment_id
  compartment_name      = local.env_vars.locals.compartment_name
  vcn_id                = dependency.vcn.outputs.id
  cluster_name          = dependency.cluster.outputs.name
  kubernetes_namespace  = dependency.cluster.outputs.name
  service_id_secret     = local.env_vars.locals.service_id_secret
  approved_senders      = local.approved_senders
  dns_names             = local.env_vars.locals.dns_names
  cert_files            = {
    "dtxsandboxmongodb1.crt" = <<-EOF
    -----BEGIN CERTIFICATE-----
    MIIDkTCCAnmgAwIBAgIJAM9IbotC0/pIMA0GCSqGSIb3DQEBCwUAMEsxJDAiBgNV
    BAMMGyouc2VydmVycy5tb25nb2RpcmVjdG9yLmNvbTEWMBQGA1UECgwNU2NhbGVH
    cmlkIEluYzELMAkGA1UEBhMCVVMwHhcNMjMxMDI0MTc1MjU4WhcNMzMxMDIxMTc1
    MjU4WjBLMSQwIgYDVQQDDBsqLnNlcnZlcnMubW9uZ29kaXJlY3Rvci5jb20xFjAU
    BgNVBAoMDVNjYWxlR3JpZCBJbmMxCzAJBgNVBAYTAlVTMIIBIjANBgkqhkiG9w0B
    AQEFAAOCAQ8AMIIBCgKCAQEAy3GaWXFI79G6mwEDRSlJCyX2zt59neCS2jVoBpr3
    GYnqB+njeUqiPcvAWrcLjGYMb+xvNBp16ddT4iKB6Bpk/bQS0nfHKD3Z/Kl5CE+U
    XlNH+qpY1oJSux8YRoLso5OY9OXh2wPK84Sjz1YhEQ4Dg1IBivkrU6uBvd0j0kd8
    yq7INtgi9s/xKoC1EmuzL0bBcXoJlkNA+ICkNDXZ9YlUvGbXBNw+PDXrPHILWfwy
    xUO0TvUn8OQRTlaGxwd6cYNI+a36T7/JTE3zy4JPtb3QFWlqDUgdEYWVCu3vzrMZ
    CZR62KKyjYxGxkzvMf2JIa5knqbZPlMeSqMqrgbWOAflowIDAQABo3gwdjAMBgNV
    HRMEBTADAQH/MB0GA1UdDgQWBBQz6qiRWR2A+J5fJSkCeO2fMdUlDDAfBgNVHSME
    GDAWgBQz6qiRWR2A+J5fJSkCeO2fMdUlDDAmBgNVHREEHzAdghsqLnNlcnZlcnMu
    bW9uZ29kaXJlY3Rvci5jb20wDQYJKoZIhvcNAQELBQADggEBAMBZSZ75qo4zJvae
    gTm7scwIOKzAiic/rOw0Ri6rpwSqHDbIYxUejBywgESorwes2DYID4e0YX/6x9no
    TT0NBh0zKLu81pjR4omTvByU+9xZYiKojhgOAHjlH+mbGItrFnNPyi9AA8X7OYs3
    ftYldo2MX9T57OvGL5biqZOS5D/aB0FUjF3FpV7+w/bi1D0eMn2d+G8pCBD9Rnbp
    jQz6PHo7pnmWRseao7pkeaY9uQQgCN7utQCn5/6EyoOmTj8ggza8P6WPRKcu4ZyC
    GCn/lrf7x020vl7PfRwcJCzzx3vuNurGBsDk6qr7hwI508/M31JLz/5fUecPJL+u
    eX6h4rE=
    -----END CERTIFICATE-----
    EOF
  }
}
