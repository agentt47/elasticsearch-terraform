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
