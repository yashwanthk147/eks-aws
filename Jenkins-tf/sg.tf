resource "aws_security_group" "ingress-ssh-test" {
  name   = "allow-ssh-sg"
  ingress = [
    for port in [22, 80, 443, 8080, 9000, 3000, 5000, 8086, 9090] : {
        description      = "TLS from VPC"
        from_port        = port
        to_port          = port
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = []
        prefix_list_ids  = []
        security_groups  = []
        self             = false
    }
  ]

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}