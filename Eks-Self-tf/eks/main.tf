resource "aws_eks_cluster" "eks" {
  name     = "${var.cluster_name}-${var.env}"
  role_arn = aws_iam_role.eks-cluster-role.arn
  version  = "1.29"

  vpc_config {
    subnet_ids              = var.eks_cluster_subnet_ids
    endpoint_private_access = var.endpoint-private-access
    endpoint_public_access  = var.endpoint-public-access
    security_group_ids      = [aws_security_group.eks-cluster-sg.id]
  }


  access_config {
    authentication_mode                         = "CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
  ]

  tags = {
    Name = "${var.cluster_name}-${var.env}"
  }
}

data "aws_eks_cluster_auth" "main" {
  name = var.cluster_name
}


# EKS Node Group using the Launch Template
resource "aws_eks_node_group" "spot-node" {
  depends_on = [
    aws_eks_cluster.eks,
    aws_iam_role_policy_attachment.eks-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks-AmazonWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks-AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.eks-AmazonEBSCSIDriverPolicy
  ]
  cluster_name    = "${var.cluster_name}-${var.env}"
  node_group_name = "${var.cluster_name}-${var.env}-spot-nodes"
  subnet_ids           = var.eks_cluster_subnet_ids
  node_role_arn = aws_iam_role.eks-nodegroup-role.arn

  scaling_config {
    desired_size = var.desired_capacity_spot
    min_size     = var.min_capacity_spot
    max_size     = var.max_capacity_spot
  }

  launch_template {
    id      = aws_launch_template.eks_spot_launch_template.id
    version = "$Default"
  }

  instance_types       = var.spot_instance_types
  capacity_type       = "SPOT"
  force_update_version = true

  update_config {
    max_unavailable = 1
  }

  tags = {
    "Name" = "${var.cluster_name}-${var.env}-spot-nodes"
  }


}

# Launch Template for EKS Worker Nodes
resource "aws_launch_template" "eks_spot_launch_template" {
  name_prefix   = "${var.cluster_name}-${var.env}-lt"
  image_id      = data.aws_ami.ami.image_id
  vpc_security_group_ids = [aws_security_group.eks_workers_sg.id]
  
  tag_specifications {
    resource_type = "instance"
    tags = {
      "Name" = "${var.cluster_name}-eks_spot_launch_template"
    }
  }
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "enabled"
  }


  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      delete_on_termination = true
    }
  }

  
  tags = {
    "Name"                                      = "${var.cluster_name}-eks-node-group"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }

  lifecycle {
    create_before_destroy = true
  }
}


# OIDC Provider
resource "aws_iam_openid_connect_provider" "eks-oidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks-certificate.certificates[0].sha1_fingerprint]
  url             = data.tls_certificate.eks-certificate.url
}

# Cluster Security group
resource "aws_security_group" "eks-cluster-sg" {
  name        = "${var.cluster_name}-${var.env}-sg"
  description = "Security group for EKS cluster control plane communication with worker nodes"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.cluster_name}-${var.env}-sg"
  }
}

resource "aws_security_group_rule" "eks_cluster_ingress_nodes" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks-cluster-sg.id
  source_security_group_id = aws_security_group.eks_workers_sg.id
  description              = "Allow inbound traffic from the worker nodes on the Kubernetes API endpoint port"
}

resource "aws_security_group_rule" "eks_cluster_egress_kublet" {
  type                     = "egress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks-cluster-sg.id
  source_security_group_id = aws_security_group.eks_workers_sg.id
  description              = "Allow control plane to node egress for kubelet"
}

resource "aws_security_group_rule" "eks_cluster_egress_nginx" {
  type                     = "egress"
  from_port                = 8443
  to_port                  = 8443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks-cluster-sg.id
  source_security_group_id = aws_security_group.eks_workers_sg.id
  description              = "Allow control plane to node egress for nginx"
}

# Node Security group
resource "aws_security_group" "eks_workers_sg" {
  name        = "${var.cluster_name}-${var.env}-workers-sg"
  description = "Security group for all nodes in the cluster"
  vpc_id      = var.vpc_id

  tags = {
    Name                                        = "${var.cluster_name}-${var.env}-workers-sg"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

resource "aws_security_group_rule" "worker_node_ingress_nginx" {
  type                     = "ingress"
  from_port                = 8443
  to_port                  = 8443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_workers_sg.id
  source_security_group_id = aws_security_group.eks-cluster-sg.id
  description              = "Allow control plane to node ingress for nginx"
}

resource "aws_security_group_rule" "worker_node_to_worker_node_ingress_coredns_tcp" {
  type              = "ingress"
  from_port         = 53
  to_port           = 53
  protocol          = "tcp"
  security_group_id = aws_security_group.eks_workers_sg.id
  self              = true
  description       = "Allow workers nodes to communicate with each other for coredns TCP"
}

resource "aws_security_group_rule" "worker_node_to_worker_node_ingress_coredns_udp" {
  type              = "ingress"
  from_port         = 53
  to_port           = 53
  protocol          = "udp"
  security_group_id = aws_security_group.eks_workers_sg.id
  self              = true
  description       = "Allow workers nodes to communicate with each other for coredns UDP"
}

resource "aws_security_group_rule" "worker_node_ingress_kublet" {
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_workers_sg.id
  source_security_group_id = aws_security_group.eks-cluster-sg.id
  description              = "Allow control plane to node ingress for kubelet"
}

resource "aws_security_group_rule" "worker_node_to_worker_node_ingress_ephemeral" {
  type              = "ingress"
  from_port         = 1025
  to_port           = 65535
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.eks_workers_sg.id
  description       = "Allow workers nodes to communicate with each other on ephemeral ports"
}

resource "aws_security_group_rule" "worker_node_egress_internet" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eks_workers_sg.id
  description       = "Allow outbound internet access"
}


############################################################################################################
# PLUGINS
############################################################################################################
data "aws_eks_addon_version" "main" {
  for_each = { for addon in var.addons : addon.name => addon }

  addon_name         = each.key
  kubernetes_version = aws_eks_cluster.eks.version
}

resource "aws_eks_addon" "main" {
  for_each = { for addon in var.addons : addon.name => addon }

  cluster_name                = "${var.cluster_name}-${var.env}"
  addon_name                  = each.key
  addon_version               = data.aws_eks_addon_version.main[each.key].version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  depends_on = [
    aws_eks_node_group.spot-node
  ]
}
