variable "region" {
  default = "ap-southeast-1"
}

variable "vpc_cidr" {
  default = "172.16.0.0/20"
}

variable "subnet_cidrs" {
  default = ["172.16.0.0/22", "172.16.4.0/22"]
}

variable "my_ip" {
  description = "your workstation IP in /32 notation — e.g. 1.2.3.4/32"
  type        = string
}
