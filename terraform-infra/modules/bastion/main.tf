data "aws_ami" "bastion_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_eip" "bastion_eip" {
  domain = "vpc"

  tags = {
    Name = "bastion-eip"
  }
}

resource "aws_eip_association" "bastion_eip_assoc" {
  allocation_id = aws_eip.bastion_eip.id
  instance_id = aws_instance.bastion.id
  depends_on = [aws_internet_gateway.main_igw]
  
}

resource "aws_instance" "bastion" {
  ami           = data.aws_ami.bastion_ami.id
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = var.subnet_id
  security_groups = [var.security_group_name]
  iam_instance_profile = var.iam_instance_profile
 associate_public_ip_address = true
  tags = {
    Name = "bastion-ec2"
  }

  metadata_options {
    http_tokens = "required"
    http_endpoint = "enabled"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    delete_on_termination = true
    encrypted = true
  }
}