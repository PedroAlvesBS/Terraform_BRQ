#Global Variables
 
variable “aw”{
	type = string
	description = “This is my availability zone”
	default = "us-east-1a"
}

variable “region”{
	type = string
	description = “This is the region I am using” 
	default = "us-east-1"
}

variable “ipv4nulled”{
	type = string
	description = “This is a nulled default IPV4” 
	default = "0.0.0.0/0"
}

variable “ipv6nulled”{
	type = string
	description = “This is a nulled default IPV6”  
	default = "::/0"
}

variable “private_IP”{
	type = string
	description = “This is the private IP, I am using”  
	default = "10.0.1.51"
}

variable “ami_t”{
	type = string
	description = “This is the image used”  
	default = "ami-04505e74c0741db8d"
}

variable “instance_t”{
	type = string
	description = “This is the instance type”  
	default = "t2.micro"
}

terraform {
 required_providers {
   aws = {
     source  = "hashicorp/aws"
     version = "3.74.0"
   }
 }
}

provider "aws" {
 #access_key = 
 #secret_key = 
 region     = var.region
 
}

resource "aws_vpc" "vpc_brq" {
 cidr_block = "10.0.0.0/16"
 tags = {
   Name = "VPC_legal"
 }
}

resource "aws_internet_gateway" "gw_brq" {
 vpc_id = aws_vpc.vpc_brq.id
 tags = {
   Name = "MyGateway"
 }
}

resource "aws_route_table" "rotas_brq" {
 vpc_id = aws_vpc.vpc_brq.id
 
 route {
   cidr_block = var.ipv4nulled
   gateway_id = aws_internet_gateway.gw_brq.id
 }
 
 route {
   ipv6_cidr_block = var.ipv6nulled
   gateway_id      = aws_internet_gateway.gw_brq.id
 }
 
 tags = {
   Name = "TabDeRoutes"
 }
}
 
resource "aws_subnet" "subrede_brq" {
 vpc_id            = aws_vpc.vpc_brq.id
 cidr_block        = "10.0.1.0/24"
 availability_zone = var.aw
 tags = {
   Name = "SubZero"
 }
}
 
resource "aws_route_table_association" "associacao" {
 subnet_id      = aws_subnet.subrede_brq.id
 route_table_id = aws_route_table.rotas_brq.id
}
 
resource "aws_security_group" "firewall" {
 name        = "abrir_portas"
 description = "Abrir porta 22 (SSH), 443 (HTTPS) e 80 (HTTP)"
 vpc_id      = aws_vpc.vpc_brq.id
 
 ingress {
   description = "HTTPS"
   from_port   = 443
   to_port     = 443
   protocol    = "tcp"
   cidr_blocks = [var.ipv4nulled]
 }
 
 ingress {
   description = "SSH"
   from_port   = 22
   to_port     = 22
   protocol    = "tcp"
   cidr_blocks = [var.ipv4nulled]
 }
 
 ingress {
   description = "HTTP"
   from_port   = 80
   to_port     = 80
   protocol    = "tcp"
   cidr_blocks = [var.ipv4nulled]
 }
 
 egress {
   from_port        = 0
   to_port          = 0
   protocol         = "-1"
   cidr_blocks      = [var.ipv4nulled]
   ipv6_cidr_blocks = [var.ipv6nulled]
 }
 
 tags = {
   Name = "MeuFirewall"
 }
}
 
 
resource "aws_network_interface" "interface_rede" {
 subnet_id       = aws_subnet.subrede_brq.id
 private_ips     = [var.private_IP]
 security_groups = [aws_security_group.firewall.id]
 tags = {
   Name = "MinhaInterface"
 }
}
 
resource "aws_eip" "ip_publico" {
 vpc                       = true
 network_interface         = aws_network_interface.interface_rede.id
 associate_with_private_ip = var.private_IP
 depends_on                = [aws_internet_gateway.gw_brq]
}
 
 
resource "aws_instance" "app_web" {
 ami               = var.ami_t
 instance_type     = var.instance_t
 availability_zone = var.aw
 network_interface {
   device_index         = 0
   network_interface_id = aws_network_interface.interface_rede.id
 }
 user_data = <<-EOF
              #! /bin/bash
              sudo apt-get update -y
              sudo apt-get install -y apache2
              sudo systemctl start apache2
              sudo systemctl enable apache2
              sudo bash -c 'echo "<h1>ESTOU RODANDO NO AWS ACREDITA?</p> </h1>"  > /var/www/html/index.html'
            EOF
 tags = {
   Name = "EC2Terraform"
 }
}
 
output "printar_ip_publico" {
 value = aws_eip.ip_publico.public_ip
}
