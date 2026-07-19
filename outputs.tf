output "instance_id" {
  value = aws_instance.ros2_robotics.id
}

output "public_ip" {
  value = aws_instance.ros2_robotics.public_ip
}

output "dcv_url" {
  value = "https://${aws_instance.ros2_robotics.public_ip}:8443"
}
