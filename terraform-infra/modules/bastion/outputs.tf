output "ami_id" {
  value = data.aws_ami.bastion_ami.id
}

output "bastion_public_ip" {
  value = aws_eip.bastion_eip.public_ip
  description = "The public IP address of the bastion instance"
}

output "bastion_instance_id" {
  value = aws_instance.bastion.id
  description = "The ID of the bastion instance"
}

output "bastion_instance_private_ip" {
    description = "The private IP address of the bastion instance"
  value = aws_instance.bastion.private_ip
}