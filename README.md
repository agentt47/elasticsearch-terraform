# elasticsearch-terraform - Elasticsearch cluster 3 node setup on AWS using Terraform


This project will create an elasticsearch cluster in AWS on t2.micro EC2 instance. The cluster is located in VPC inside subnet.

## Requirements

* Terraform >= v0.6.15
* Aws cli 

## Installation

Install Terraform - 

Use yum-config-manager to add the official HashiCorp Linux repository.

    $ sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo

    $ sudo yum -y install terraform

Install AWS cli -

    $ curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    $ unzip awscliv2.zip
    # sudo ./aws/install

## Configuration

### AWS Credentials - Setup profile using aws configure 

Terraform will use the credentials to create aws resources.

    [ec2-user@ip-20-0-1-61 ~]$ aws configure

    AWS Access Key ID [****************D77X]:

    AWS Secret Access Key [****************8rPi]:

    Default region name [us-east-1]:

    Default output format [None]:


### Terraform configuration file:

1: provider.tf - Aws provider details to build resources in aws using terraform

    provider "aws" {
      region = "us-east-1"
      profile = "default"
    }

2: var.tf - Variable file to create aws resources

    variable "VPC_cidr_block" 
    {
      type = string
      description = "Enter CIDR Block for VPC:" 
    }

    variable "Subnet_cidr_block"
    {
     type = string
      description = "Enter CIDR Block for Subnet:" 
    }

    variable "azone"
    {
      type = string
     description = "Enter Availability Zone:" 
    }

    variable "from_port"
    {
     type = string
      description = "Enter From Port:" 
    }

    variable "to_port" 
    {
       type = string
      description = "Enter To Port:" 
    }

    variable "security_cidr"
    {
      type = string
      description = "Enter Security Group CIDR:" 
    }

    variable "protocol"
    {
      type = string
      description = "Enter Security group protocol:" 
    }


    variable "num"
    {
     type = number
     description = "Enter Number of Instance to create:" 
    }

    variable "key"
    {
      type = string
     description = "Enter Key Pair Name:" 
    }

3: vpc.tf - Create VPC for elasticsearch cluster

    resource "aws_vpc" "ElasticVPC" {
    cidr_block = var.VPC_cidr_block
    tags = {
    Name = "ElasticVPC"
    }
    }
    resource "aws_subnet" "Public_Elastic" {
    vpc_id     = aws_vpc.ElasticVPC.id
    cidr_block = var.Subnet_cidr_block
    map_public_ip_on_launch = true
    availability_zone = var.azone
    tags = {
    Name = "Public-Elastic-Subnet"
    }
    }

4: ig.tf & ec2.tf - Create and update route table and launch ec2 nodes on aws.

    resource "aws_internet_gateway" "IG" {
    vpc_id = aws_vpc.ElasticVPC.id
    tags = {
    Name = "IG-Elastic"
    }
    }

      resource "aws_route_table" "Elastic_Route" {
      vpc_id = aws_vpc.ElasticVPC.id

      route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.IG.id
      }
      tags = {
      Name = "Elastic-Route"
      }
      }

    resource "aws_route_table_association" "ES" {
    subnet_id      = aws_subnet.Public_Elastic.id
    route_table_id = aws_route_table.Elastic_Route.id
    }


    resource "aws_security_group" "ssh-allowed" {
    vpc_id = aws_vpc.ElasticVPC.id
    
    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
 	  from_port = var.from_port
        to_port = var.to_port
        protocol = var.protocol
        // This means, all ip address are allowed to ssh !
        // You can Put Specific IP Address Allowed Internet Traffic for simplicity
        cidr_blocks = [var.security_cidr]

    }
    tags = {
        Name = "ssh-allowed"
    }
    }

    resource "aws_instance" "ElasticSearchNode"{
    ami           = "ami-061ac2e015473fbe2"
    instance_type = "t2.micro"
    count = var.num
    private_ip = var.private_ip[count.index]
    key_name = var.key
    vpc_security_group_ids = [aws_security_group.ssh-allowed.id]
    user_data = "${file("boot.sh")}"
    subnet_id = aws_subnet.Public_Elastic.id
    tags = {
    Name = "ElasticSearch-Node"
    }
     }
      output "instances" {
        value       = "${aws_instance.ElasticSearchNode.*.public_ip}"
        description = "PublicIP address details"
        }

5: boot.sh - user-data bootstarp script for EC2 instances executed during launch and install java, elasticsearch binaries and configure java heap cinfiguration for elasticsearch to 512m.

    #!/bin/bash
    yum install java-1.8.0-openjdk.x86_64 -y
    mkdir /home/ec2-user/ES
    cd /home/ec2-user/ES
    wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.9.2-x86_64.rpm
    rpm -ivh elasticsearch-7.9.2-x86_64.rpm
    sed -i 's/-Xm.*1g/-Xms512m/g' /etc/elasticsearch/jvm.options

## Execute Terraform confiuration 

Change directory to terraform code and execute terraform  plan and apply commands.

    $ cd /home/ec2-user/elastic
    $ terraform plan
    $ terraform apply


