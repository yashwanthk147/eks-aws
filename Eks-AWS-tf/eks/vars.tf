variable "env" {}
variable "cluster_name" {}
variable "eks_cluster_subnet_ids" {}

# variable "private_subnet_ids" {
#   type = list(string)
#   description = "List of private subnet IDs."
# }

# variable "public_subnet_ids" {
#   type = list(string)
#   description = "List of public subnet IDs."
# }
variable "endpoint-private-access" {}
variable "endpoint-public-access" {}
variable "vpc_id" {}


variable "spot_instance_types" {}
variable "desired_capacity_spot" {}
variable "min_capacity_spot" {}
variable "max_capacity_spot" {}
variable "addons" {
  type = list(object({
    name    = string
    version = string
  }))
}



