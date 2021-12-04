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

Change directory to terraform code and execute terraform  plan and apply commands.Check snippet for command ouput below is sample.

    $ cd /home/ec2-user/elastic
    $ terraform plan
    $ terraform apply
    [ec2-user@ip-172-31-39-51 elastic]$ terraform apply
         var.Subnet_cidr_block
         Enter CIDR Block for Subnet:
         Enter a value: 20.0.1.0/24
         var.VPC_cidr_block
         Enter CIDR Block for VPC:
         Enter a value: 20.0.0.0/16
         var.azone
         Enter Availability Zone:
         Enter a value: us-east-1a
         var.from_port
         Enter From Port:
         Enter a value: 0
         var.key
         Enter Key Pair Name:
         Enter a value: ES
         var.num
         Enter Number of Instance to create:
         Enter a value: 3
         var.protocol
         Enter Security group protocol:
         Enter a value: -1
         var.security_cidr
         Enter Security Group CIDR:
         Enter a value: 0.0.0.0/0
         var.to_port
         Enter To Port:
         Enter a value: 0

        aws_vpc.ElasticVPC: Refreshing state... [id=vpc-0cf6571f16c775618]
        aws_security_group.ssh-allowed: Refreshing state... [id=sg-0b1780b84d799507e]
        aws_internet_gateway.IG: Refreshing state... [id=igw-05b12a5ac58d4d423]
        aws_subnet.Public_Elastic: Refreshing state... [id=subnet-02c39f1b5baedab57]
        aws_instance.ElasticSearchNode[2]: Refreshing state... [id=i-080975f920770c17f]
        aws_instance.ElasticSearchNode[0]: Refreshing state... [id=i-040fa749ec7a79230]
        aws_instance.ElasticSearchNode[1]: Refreshing state... [id=i-0de8fa5891e93c265]
        aws_route_table.Elastic_Route: Refreshing state... [id=rtb-0dfe2f05121e9eff9]
        aws_route_table_association.ES: Refreshing state... [id=rtbassoc-044f8f6937c9913b0]
        No changes. Your infrastructure matches the configuration.

## Configure elasticsearch.yml for cluster

Edit /etc/elasticsearch/elasticsearch.yml file on nodes to setup cluster.

## Master node Configuration

        node.name: 20.0.1.105
        network.host: 20.0.1.105
        discovery.zen.ping.unicast.hosts: ["20.0.1.105","20.0.1.61","20.0.1.157"]
        discovery.zen.minimum_master_nodes: 2
        cluster.name: elasticsearch
        cluster.initial_master_nodes: ["20.0.1.105"]

## Data node Configuration
    Node1:
        node.name: 20.0.1.61
        network.host: 20.0.1.61
        discovery.zen.ping.unicast.hosts: ["20.0.1.105","20.0.1.61","20.0.1.157"]
        discovery.zen.minimum_master_nodes: 2
        cluster.name: elasticsearch
        cluster.initial_master_nodes: ["20.0.1.105"]

    Node2:
        node.name: 20.0.1.157
        network.host: 20.0.1.157
        discovery.zen.ping.unicast.hosts: ["20.0.1.105","20.0.1.61","20.0.1.157"]
        discovery.zen.minimum_master_nodes: 2
        cluster.name: elasticsearch
        cluster.initial_master_nodes: ["20.0.1.105"]
        

## Starting elasticsearch service on all nodes

elasticsearch service will start and setup 3 node cluster with master node.

        $service elasticsearch start
        
## Cluster health ouput

    [root@ip-20-0-1-105 elasticsearch]# curl -X GET "20.0.1.105:9200/_cluster/health?pretty"
    {
    "cluster_name" : "elasticsearch",
    "status" : "green",
    "timed_out" : false,
    "number_of_nodes" : 3,
    "number_of_data_nodes" : 3,
    "active_primary_shards" : 2,
    "active_shards" : 4,
    "relocating_shards" : 0,
    "initializing_shards" : 0,
    "unassigned_shards" : 0,
    "delayed_unassigned_shards" : 0,
    "number_of_pending_tasks" : 0,
    "number_of_in_flight_fetch" : 0,
    "task_max_waiting_in_queue_millis" : 0,
    "active_shards_percent_as_number" : 100.0
       }

## Node status output:
    [root@ip-20-0-1-61 elasticsearch]# curl -X GET "20.0.1.105:9200/_cat/nodes?v=true"
        ip         heap.percent ram.percent cpu load_1m load_5m load_15m node.role master name
        20.0.1.105           39          92   9    0.05    0.13     0.07 dilmrt    -      20.0.1.105
        20.0.1.157           26          93   9    0.04    0.11     0.05 dilmrt    *      20.0.1.157
        20.0.1.61            59          94  10    0.09    0.15     0.07 dilmrt    -      20.0.1.61

## PUT and GET data

Put: curl -H 'Content-Type: application/json' -X POST 'http://20.0.1.105:9200/test/hellonitinnegi/1' -d '{ "message": "Hello Nitin Negi!" }'

    [root@ip-20-0-1-157 elasticsearch]# curl -H 'Content-Type: application/json' -X POST 'http://20.0.1.105:9200/test/hellonitinnegi/1' -d '{ "message": "Hello Nitin Negi!" }'
        {"_index":"test","_type":"hellonitinnegi","_id":"1","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":0,"_primary_term":1}            [root@ip-20-0-1-157 elasticsearch]#

 Get: curl -X GET 'http://20.0.1.105:9200/test/hellonitinnegi/1?pretty'      

        [root@ip-20-0-1-157 elasticsearch]# curl -X GET 'http://20.0.1.105:9200/test/hellonitinnegi/1?pretty'
        {
        "_index" : "test",
        "_type" : "hellonitinnegi",
        "_id" : "1",
        "_version" : 1,
        "_seq_no" : 0,
        "_primary_term" : 1,
        "found" : true,
        "_source" : {
        "message" : "Hello Nitin Negi!"
        }
        }

## Security using user and certificate

- Set passwords for default users
       
       cd /usr/share/elasticsearch
       bin/elasticsearch-setup-passwords interactive

- Add new user
       
       bin/elasticsearch-users useradd nitin -p Abc1234
       
- Create Certificate and update elasticsearch.yml file

        cd /usr/share/elasticsearch
        bin/elasticsearch-certutil ca
        bin/elasticsearch-certutil cert --ca elastic-stack-ca.p12
 
 -  Copy and paste following lines in elasticsearch.yml file
        
        xpack.security.enabled: true
        xpack.security.transport.ssl.enabled: true
        xpack.security.transport.ssl.verification_mode: certificate
        xpack.security.transport.ssl.keystore.path: elastic-certificates.p12
        xpack.security.transport.ssl.truststore.path: elastic-certificates.p12
        
  ## Cluster info using elastic user
  
 Error connecting without user: curl -X GET 'http://20.0.1.105:9200/_cat/nodes?v=true'
  
        [ec2-user@ip-20-0-1-157 ~]$ curl -X GET 'http://20.0.1.105:9200/_cat/nodes?v=true'
        {"error":{"root_cause":[{"type":"security_exception","reason":"missing authentication credentials for REST request [/_cat/nodes?v=true]","header":{"WWW-  

Connected with user and password: curl -u  elastic:iuZaBsJoCUBKoqFqXy6s -X GET 'http://20.0.1.105:9200/_cat/nodes?v=true'
 
        [ec2-user@ip-20-0-1-157 ~]$ curl -u  elastic:iuZaBsJoCUBKoqFqXy6s -X GET 'http://20.0.1.105:9200/_cat/nodes?v=true'
                 ip         heap.percent ram.percent cpu load_1m load_5m load_15m node.role master name
                 20.0.1.105           41          93   0    0.00    0.00     0.00 dilmrt    -      20.0.1.105
                 20.0.1.157           24          93   1    0.00    0.00     0.00 dilmrt    *      20.0.1.157
                 20.0.1.61            66          92   0    0.00    0.00     0.00 dilmrt    -      20.0.1.61

               
 
