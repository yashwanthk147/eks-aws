resource "aws_spot_instance_request" "jump-vm" {
  ami                    = data.aws_ami.ami.image_id
  instance_type          = "t3.medium"
  availability_zone      = "us-east-1a"
  key_name               = var.key-name
  associate_public_ip_address = true
  monitoring             = false
  spot_type     = "persistent"
  instance_interruption_behavior = "stop"
  iam_instance_profile   = aws_iam_instance_profile.instance-profile.name


  ebs_optimized = false
  
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    iops                  = 3000
    throughput            = 125
    delete_on_termination = true
  }

  ebs_block_device {
    device_name           = "/dev/xvdbs"
    volume_type           = "gp3"
    volume_size           = 40
    iops                  = 3000
    throughput            = 125
    delete_on_termination = false
  }

  vpc_security_group_ids = ["${aws_security_group.jump-ssh-test.id}"]
  subnet_id              = "subnet-0b66824957e4acbc2"

  tags = {
    Name = var.instance-name
  }
}


resource "null_resource" "jump-vm" {
  depends_on = [aws_spot_instance_request.jump-vm]

  # provisioner "local-exec" {
  #   command = "sleep 30" 
  # }

  # First, copy the install.sh file to the remote server
  provisioner "file" {
    source      = "install.sh"
    destination = "/home/ubuntu/install.sh"
    connection {
      host        = aws_spot_instance_request.jump-vm.public_ip
      user        = "ubuntu"
      private_key = file("C:/Users/Yashwanth Reddy/Downloads/yashwanth-vm.pem")
    }
  }

  # Then, execute the script on the remote server
  provisioner "remote-exec" {
    connection {
      host        = aws_spot_instance_request.jump-vm.public_ip
      user        = "ubuntu"
      private_key = file("C:/Users/Yashwanth Reddy/Downloads/yashwanth-vm.pem")
    }

    inline = [
      "cd /home/ubuntu",
      "chmod +x install.sh",
      "./install.sh"
    ]
  }
}