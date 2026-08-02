output "vpc_id"        { value = aws_vpc.main.id }
output "subnet_a_id"   { value = aws_subnet.pub_a.id }
output "subnet_b_id"   { value = aws_subnet.pub_b.id }
output "ec2_public_ip" { value = aws_instance.web.public_ip }
