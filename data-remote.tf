data "terraform_remote_state" "vpc" {
  backend = "remote"
  config = {
    organization = var.remote_state_org
    workspaces = { name = var.remote_state_vpc_ws } # workspace del módulo VPC
  }
}

# (opcional) si querés SG de tasks desde el cluster/servicio
data "terraform_remote_state" "ecs" {
  backend = "remote"
  config = {
    organization = var.remote_state_org
    workspaces = { name = var.remote_state_cluster_ws } # o servicio
  }
}

data "terraform_remote_state" "bastion" {
  backend = "remote"
  config = {
    organization = var.remote_state_org
    workspaces   = { name = var.remote_state_vpc_ws }
  }
}
