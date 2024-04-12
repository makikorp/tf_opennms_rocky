
locals {
  azs = data.aws_availability_zones.available.names
}

data "aws_availability_zones" "available" {}

resource "random_id" "random" {
  byte_length =2
}

resource "aws_vpc" "eric_main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "dev-vpc-${random_id.random.dec}"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_subnet" "eric_public_subnet" {
  count                   = length(var.public_cidrs)
  vpc_id                  = aws_vpc.eric_main_vpc.id
  #cidr_block              = "10.0.1.0/24"
  cidr_block             = cidrsubnet(var.vpc_cidr, 8, count.index)
  map_public_ip_on_launch = true
  #availability_zone       = "us-west-2a"
  availability_zone = local.azs[count.index] # - uses local value defined above
  #availability_zone = data.aws.availability_zones.available.names[count.index]

  tags = {
    Name = "dev-public-subnet"
    #Name = "dev-public-subnet-${count.index + 1}"
  }
}

#in console use cidrsubnet function to calculate a subnet address
#cidrsubnet("10.0.0.0/16", 8, 1) - 8 new bits to increase to /24, 1 add to network "10.0.1.0/24"
#cidrsubnet("var.vpc_cidr", 8, 2)
#how to prevent public and private cidrs from colliding
#cidrsubnet("var.vpc_cidr", 8, length(local.azs) + 1)

#change above for public to be
#count = length(local.azs)
#cidr_block = cidrsubnet("var.vpc_cidr", 8, count.index)
#change above for private to be
#count = length(local.azs)
#cidr_block = cidrsubnet("var.vpc_cidr", 8, length(local.azs) + count.index)

resource "aws_subnet" "eric_private_subnet" {
  count                   = length(var.private_cidrs)
  vpc_id                  = aws_vpc.eric_main_vpc.id
  #cidr_block              = "10.0.3.0/24"
  cidr_block             = cidrsubnet(var.vpc_cidr, 8, count.index + length(local.azs))
  map_public_ip_on_launch = false
  #availability_zone       = "us-west-2a"
  availability_zone = local.azs[count.index]

  tags = {
    Name = "dev-private-subnet"
    #Name = "dev-private-subnet-${count.index + 1}"
  }
}


resource "aws_internet_gateway" "eric_internet_gateway" {
  vpc_id = aws_vpc.eric_main_vpc.id

  tags = {
    Name = "dev-internetgateway-${random_id.random.dec}"
  }
}

resource "aws_route_table" "eric_public_rt" {
  vpc_id = aws_vpc.eric_main_vpc.id

  tags = {
    Name = "dev-public-rt"
  }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.eric_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.eric_internet_gateway.id
}

resource "aws_default_route_table" "eric_private_rt" {
  default_route_table_id = aws_vpc.eric_main_vpc.default_route_table_id

  tags = {
    Name = "eric_private_rt"
  }
}

resource "aws_route_table_association" "eric_public_assoc" {
  count = length(local.azs)
  #subnet_id      = aws_subnet.eric_public_subnet.id
  subnet_id     = aws_subnet.eric_public_subnet.*.id[0] #[count.index]  
  # * = "splat" 
  #puts the created subnets in a list and pull from that list.  This is the same as below
  #subnet_id     = aws_subnet.eric_public_subnet.[count.id].id
  route_table_id = aws_route_table.eric_public_rt.id
}

#private submets default to the default route table.  Private subnet doesn't need to have
#the association explicitly declared

resource "aws_security_group" "eric_security_group" {
  name        = "dev_sg"
  description = "dev_security_group"
  vpc_id      = aws_vpc.eric_main_vpc.id

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1" #any protocol tcp = 6
    cidr_blocks      = ["0.0.0.0/0"]
    #ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    #ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "dev_secgroup"
  }
}

#can create ingress and egress resources

#resource "aws_security_group_rule" "ingress all"
#    type = "ingress" 
#    from_port        = 0
#    to_port          = 65535
#    protocol         = "-1" #any protocol tcp = 6
#    cidr_blocks      = [var.access_ip]
#    security_group_id = aws_security_group.dev_sg.id


#resource "aws_security_group_rule" "egress all"
#    type = "ingress" 
#    from_port        = 0
#    to_port          = 65535
#    protocol         = "-1" #any protocol tcp = 6
#    cidr_blocks      = ["0.0.0.0/0"]
#    security_group_id = aws_security_group.dev_sg.id




#ssh-keygen -t rsa

#resource "aws_key_pair" "eric_auth" {
#  key_name   = "ericAWSkey"
#  #public_key = "SHA256:wgoPLfqOvqc2GOX2TdfMnzZEduaUYxn8N83zHGjfi2E"
#  public_key = file("~/.ssh/ericAWSkey.pub")
#}

############### below in eric_compute.tf

#resource "aws_instance" "master" {
#  ami           = data.aws_ami.ubuntu_server.id
#  instance_type = "t3.small"
#  key_name = aws_key_pair.eric_auth.id
#  vpc_security_group_ids = [aws_security_group.eric_security_group.id]
#  subnet_id = aws_subnet.eric_public_subnet.id
#
#  user_data = file("commonmaster.tpl")
#
#
#  root_block_device {
#    volume_size = 10
#  }
#
#  tags = {
#    Name = "master"
#  }
#}