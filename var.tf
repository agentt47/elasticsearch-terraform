variable "VPC_cidr_block" {
  type = string
  description = "Enter CIDR Block for VPC:" 
}

variable "Subnet_cidr_block" {
  type = string
  description = "Enter CIDR Block for Subnet:" 
}

variable "azone" {
  type = string
  description = "Enter Availability Zone:" 
}

variable "from_port"{
  type = string
  description = "Enter From Port:" 
}

variable "to_port" {
  type = string
  description = "Enter To Port:" 
}

variable "security_cidr" {
  type = string
  description = "Enter Security Group CIDR:" 
}

variable "protocol" {
  type = string
  description = "Enter Security group protocol:" 
}


variable "num"{
  type = number
  description = "Enter Number of Instance to create:" 
}

variable "key" {
  type = string
  description = "Enter Key Pair Name:" 
}

variable "private_ip" {
  type = list
  default = ["20.0.1.105","20.0.1.61","20.0.1.157"]
  description = "Enter Private IP for instance:" 
}

