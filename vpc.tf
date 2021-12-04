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
