variable "vpc" {}
variable "env" {}
variable "eks" {
  type = map(object({
    cluster-name             = string
    endpoint-private-access  = bool
    endpoint-public-access   = bool
    spot_instance_types      = list(string)
    desired_capacity_spot    = number
    min_capacity_spot        = number
    max_capacity_spot        = number
    addons                   = list(object({
      name    = string
      version = string
    }))
  }))
}

# variable "eks-sg" {}


# variable "endpoint-private-access" {}
# variable "endpoint-public-access" {}