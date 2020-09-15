output "lb_dns" {
  value = aws_lb.main.dns_name
}

output "instances_bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "instances_public_ips" {
  value = aws_instance.public.*.private_ip
}

output "instances_private_ips" {
  value = aws_instance.private.*.private_ip
}

output "nat_gateway_public_ip" {
  value = aws_eip.nat.public_ip
}

output "ssh_private_key" {
  value = tls_private_key.main.private_key_pem
}

output "ssh_public_key" {
  value = tls_private_key.main.public_key_openssh
}