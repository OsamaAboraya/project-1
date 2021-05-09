
# Configure the AWS Provider
provider "aws" {
  region = "us-east-2"
  access_key = "AKIAU3HD7MCVMQSZ5NWS"
  secret_key = "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"
}



resource "aws_vpc" "vpc1" {
  cidr_block       = "10.88.0.0/16"

   tags = {
    Name = "vpc1-terraform"
  }

  
}
resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.vpc1.id
  cidr_block = "10.88.1.0/24"
 tags = {
    Name = "subnet-public-terraform"
  }
  
}

resource "aws_subnet" "subnet2" {
  vpc_id     = aws_vpc.vpc1.id
  cidr_block = "10.88.2.0/24"
  

 tags = {
    Name = "subnet-private-terraform"
  } 
}



  
resource "aws_instance" "ter2" {
  ami           = "ami-00399ec92321828f5"
  instance_type = "t2.micro"
  key_name = "key"
  network_interface {
    network_interface_id = aws_network_interface.awsinterface2.id
    device_index = 0
  }
  user_data = <<-EOF
		#! /bin/bash
    sudo apt update -y
    sudo apt install -y docker.io
    sudo docker pull mysql
    sudo docker run -itd -e MYSQL_ROOT_PASSWORD=wordpress -e MYSQL_DATABASE=wordpress -e MYSQL_USER=wordpress -e MYSQL_PASSWORD=wordpress -p 3306:3306 mysql 
  EOF
  tags = {
    Name = "instance-private-terraform"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc1.id

  tags = {
    Name = "internet_gateway-terraform"
  }
}
resource "aws_eip" "lb" {
  vpc = true

}


resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.lb.id
  subnet_id = aws_subnet.subnet1.id
  tags = {
    Name = "nat-gateway-terraform"
  }
}

resource "aws_route_table" "routetable1" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  

  tags = {
    Name = "routetable-terrafom"
  }
}
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.routetable1.id
}

resource "aws_route_table" "routetable2" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ngw.id
  }

  

  tags = {
    Name = "routetable-terraform-2"
  }
}
resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.routetable2.id
}



resource "aws_security_group" "sg" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.vpc1.id


  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "All networks allowed"
    from_port = 80
    to_port = 80
    protocol = "tcp"
  }
  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "HTTP"
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
  }

  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "HTTPS"
    from_port = 443
    to_port = 443
    protocol = "tcp"
  }

  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
  }
  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "All networks allowed"
    from_port = 0
    to_port = 0
    protocol = "-1"
  }

  egress  {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "All networks allowed"
    from_port = 0
    to_port = 0
    protocol = "-1"
  }


  tags = {
    Name = "allow_tls"
  }


}
resource "aws_eip_association" "two" {
  instance_id   = aws_instance.ter1.id
  allocation_id = aws_eip.two.id
}
resource "aws_eip" "two" {
  vpc = true
  #network_interface = aws_network_interface.ter1.id
  #associate_with_private_ip = "10.88.1.10"
}
resource "aws_network_interface" "ter1" {
  subnet_id     =  aws_subnet.subnet1.id
  private_ips = ["10.88.1.10"]
  #public_ips= ["10.88.1.10"]
  security_groups = [aws_security_group.sg.id]

}

resource "aws_instance" "ter1" {
  ami           = "ami-00399ec92321828f5"
  instance_type = "t2.micro"
  key_name = "key"
  tags = {
    Name = "instance-public-terraform"
  }

  network_interface {
    network_interface_id = aws_network_interface.ter1.id
    device_index = 0
  }
  user_data = <<-EOF
		#! /bin/bash
    sleep 30
    sudo apt update -y
    sudo apt install -y docker.io
    sudo docker pull wordpress
    sudo docker run -itd -e WORDPRESS_DB_HOST=10.88.2.10 -e WORDPRESS_DB_USER=wordpress -e WORDPRESS_DB_PASSWORD=wordpress -e WORDPRESS_DB_NAME=wordpress -p 80:80 wordpress
  EOF
  
}
resource "aws_network_interface" "awsinterface2" {
  subnet_id     =  aws_subnet.subnet2.id
  private_ips = ["10.88.2.10"]
  security_groups = [aws_security_group.sg.id]

}
