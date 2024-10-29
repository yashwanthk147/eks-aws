module "vpc" {
    source = "./vpc"
    env = var.env
    for_each = var.vpc
    vpc_cidr = each.value["vpc_cidr"]
    public_subnets = each.value["public_subnets"]
    private_subnets = each.value["private_subnets"]


}


module "eks" {
  source                    = "./eks"
  env                       = var.env
  for_each                  = var.eks
  cluster_name              = each.value["cluster-name"]
  endpoint-private-access   = each.value["endpoint-private-access"]
  endpoint-public-access    = each.value["endpoint-public-access"]
  eks_cluster_subnet_ids    = module.vpc[each.key].private_subnet_ids 
  vpc_id                    = module.vpc[each.key].vpc_id 
  spot_instance_types       = each.value["spot_instance_types"]
  desired_capacity_spot     = each.value["desired_capacity_spot"]
  min_capacity_spot         = each.value["min_capacity_spot"]
  max_capacity_spot         = each.value["max_capacity_spot"]
  addons                    = each.value["addons"]
}

output "eks_each_value_debug" {
  value = [for k, v in var.eks : "${k} - ${v.cluster-name}"]
}
