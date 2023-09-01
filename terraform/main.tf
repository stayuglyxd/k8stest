terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  zone = "ru-central1-a"
  token = "token_id"
  cloud_id = "cloud_id"
  folder_id = "folder_id"
}



module "yc-vpc" {
  source              = "github.com/terraform-yc-modules/terraform-yc-vpc.git"
  network_name        = "test-module-network"
  network_description = "Test network created with module"
  private_subnets = [{
    name           = "subnet-1"
    zone           = "ru-central1-a"
    v4_cidr_blocks = ["10.10.0.0/24"]
  },
  {
    name           = "subnet-2"
    zone           = "ru-central1-b"
    v4_cidr_blocks = ["10.11.0.0/24"]
  },
  {
    name           = "subnet-3"
    zone           = "ru-central1-c"
    v4_cidr_blocks = ["10.12.0.0/24"]
  }
  ]
}

module "kube" {
  source     = "github.com/terraform-yc-modules/terraform-yc-kubernetes.git"
  network_id = "${module.yc-vpc.vpc_id}"

  master_locations  = [
    for s in module.yc-vpc.private_subnets:
      {
        zone      = s.zone,
        subnet_id = s.subnet_id
      }
    ]

  master_maintenance_windows = [
    {
      day        = "monday"
      start_time = "23:00"
      duration   = "3h"
    }
  ]

  node_groups = {
    "yc-k8s-ng-01"  = {
      description   = "Kubernetes nodes group 01"
      fixed_scale   = {
        size = 3
      }
      node_labels   = {
        role        = "worker-01"
        environment = "testing"
      }
    },

    "yc-k8s-ng-02"  = {
      description   = "Kubernetes nodes group 02"
      auto_scale    = {
        min         = 2
        max         = 4
        initial     = 2
      }
      node_labels   = {
        role        = "worker-02"
        environment = "dev"
      }

      max_expansion   = 1
      max_unavailable = 1
    }
  }
}
