provider "aws" {
  region = var.region

}

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    "Name" = "${var.environment}-my-vpc"
  }

}


resource "aws_subnet" "my-subnet-public-1" {
  cidr_block              = var.subnet_cidr_blocks[0]
  vpc_id                  = aws_vpc.my_vpc.id
  map_public_ip_on_launch = true

  tags = {
    "Name" = "${var.environment}-my-public-subnet-1"
  }
}

resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my-igw.id
  }
  tags = {
    "Name" = "${var.environment}-public-rt"

  }

}

resource "aws_internet_gateway" "my-igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    "Name" = "my-igw"
  }

}

resource "aws_route_table_association" "my-subnet-association" {
  subnet_id      = aws_subnet.my-subnet-public-1.id
  route_table_id = aws_route_table.public-rt.id

}

data "aws_ami" "amazon-2-latest" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]

  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]

  }
}



resource "aws_key_pair" "my-server-key" {
  key_name   = "my-server-key.pem"
  public_key = file("/home/tarik/.ssh/my-server-key.pem.pub")

}

resource "aws_security_group" "allow-ssh-web" {
  name   = "allow-ssh-web"
  vpc_id = aws_vpc.my_vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Allow-ssh-web"
  }
}

resource "aws_instance" "my-server" {
  ami             = data.aws_ami.amazon-2-latest.id
  instance_type   = var.instance_type
  subnet_id       = aws_subnet.my-subnet-public-1.id
  key_name        = aws_key_pair.my-server-key.key_name
  security_groups = [aws_security_group.allow-ssh-web.id]
  
  user_data = file("./myscript.sh")

  tags = {
    "Name" = "${var.environment}-my-server"
  }

  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("/home/tarik/.ssh/my-server-key.pem")
    host = self.public_ip
    }

  provisioner "remote-exec" {
      inline = [
        "sudo yum update -y", "sudo yum install docker -y","sudo systemctl start docker","sudo docker run -d -p 80:80 nginx "
      ]
    }   

}

