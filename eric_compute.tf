# data "aws_ami" "rocky_server" {
#     most_recent = true
#     owners = ["792107900819"]
#     #owners = ["679593333241"] - procomputers
#     #image_id = "0ed8a6ecabd61fefc"

#     filter {
#         name = "name"
#         values = [" Rocky-9-EC2-Base-9.3-20231113.0.x86_64"]
#         #values = ["linux/images/hvm-ssd/rocky-blue-onyx-9.2-amd64-server-*"]
#         #values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
#     }    
# }

resource "random_id" "eric_node_id" {
  byte_length = 2
  count       = var.main_instance_count
}

resource "aws_key_pair" "eric_auth" {
  key_name = var.key_name
  public_key = file(var.public_key_path)
}

resource "aws_instance" "master" {
  count         = var.main_instance_count
  instance_type = var.main_instance_type
  #ami           = data.aws_ami.rocky_server.id
  ami            = "ami-044be8205e8972043"
  key_name = aws_key_pair.eric_auth.id
  vpc_security_group_ids = [aws_security_group.eric_security_group.id]
  subnet_id              = aws_subnet.eric_public_subnet[count.index].id
  root_block_device {
    volume_size = var.main_vol_size
  }
    tags = {
    Name = "master-${random_id.eric_node_id[count.index].dec}"
  }

  #adds EC2 instance IP address to aws hosts file -- the "aws ec2 wait" command waits for the instance to be running
  provisioner "local-exec" {
    command = "printf '\n${self.public_ip}' >> aws_hosts && aws ec2 wait instance-status-ok --instance-ids ${self.id} --region us-west-2"
  }
}

#Call and run Ansible playbook
resource "null_resource" "opennms_install" {
  depends_on = [aws_instance.master]
  provisioner "local-exec" {
    command = "ansible-playbook -i aws_hosts --key-file /Users/ericmaki/.ssh/awsTerraTest playbooks/opennms.yml"
  }
}

output "ec2_access" {
  value = {for i in aws_instance.master[*] : i.tags.Name => "${i.public_ip}:8980"}
}