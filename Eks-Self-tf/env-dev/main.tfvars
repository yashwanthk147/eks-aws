env = "dev"

vpc = {
    main = {
        vpc_cidr = "172.19.0.0/16"

        public_subnets = {
            public-az1 = {
                name = "public-az1"
                cidr_block = "172.19.0.0/24"
                availability_zone = "us-east-1a"
            }

            public-az2 = {
                name = "public-az2"
                cidr_block = "172.19.1.0/24"
                availability_zone = "us-east-1b"
            }
        }

        private_subnets = {
            pvt-az1-01 = {
                name = "pvt-az1-01"
                cidr_block = "172.19.2.0/24"
                availability_zone = "us-east-1a"
            }

            pvt-az1-02 = {
                name = "pvt-az1-02"
                cidr_block = "172.19.3.0/24"
                availability_zone = "us-east-1a"
            }

            pvt-az2-03 = {
                name = "pvt-az2-03"
                cidr_block = "172.19.4.0/24"
                availability_zone = "us-east-1b"
            }

            pvt-az2-04 = {
                name = "pvt-az2-04"
                cidr_block = "172.19.5.0/24"
                availability_zone = "us-east-1b"
            }
        }


    }
}

eks = {
    main = {
        cluster-name               = "eks-devops"
        endpoint-private-access    = true
        endpoint-public-access     = false
        spot_instance_types        = ["t3a.medium"]
        desired_capacity_spot      = 1
        min_capacity_spot          = 1
        max_capacity_spot          = 5
        addons = [
            {
                name    = "vpc-cni",
                version = "v1.18.1-eksbuild.1"
            },
            {
                name    = "coredns",
                version = "v1.11.1-eksbuild.9"
            },
            {
                name    = "kube-proxy",
                version = "v1.29.3-eksbuild.2"
            },
            {
                name    = "aws-ebs-csi-driver",
                version = "v1.30.0-eksbuild.1"
            }
            // Add more addons as needed
        ] 
    }
}
