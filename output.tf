output "my-server-public-ip" {
  value = aws_instance.my-server.public_ip
}