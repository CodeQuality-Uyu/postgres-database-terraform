data "terraform_remote_state" "vpc" {
  backend = "remote"
  config = {
    organization = var.remote_state_org
    workspaces = { name = var.remote_state_vpc_ws } # workspace del módulo VPC
  }
}
