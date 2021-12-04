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
