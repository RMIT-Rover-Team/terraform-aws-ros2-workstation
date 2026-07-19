locals {
  simple_instance_id = var.use_spot_fleet ? null : aws_instance.ros2_robotics[0].id
  simple_public_ip    = var.use_spot_fleet ? null : aws_instance.ros2_robotics[0].public_ip
}

# When using Spot Fleet, the instance isn't a directly-tracked Terraform
# resource — it's launched by AWS on the fleet's behalf. This data source
# looks it up by tag after fulfillment so we can still output its IP.
data "aws_instances" "fleet_instance" {
  count = var.use_spot_fleet ? 1 : 0

  filter {
    name   = "tag:Name"
    values = [var.instance_name]
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }

  depends_on = [aws_spot_fleet_request.ros2_fleet]
}

output "instance_id" {
  value = var.use_spot_fleet ? try(data.aws_instances.fleet_instance[0].ids[0], "pending — re-run 'terraform apply' or 'terraform refresh' once the fleet request is fulfilled") : local.simple_instance_id
}

output "public_ip" {
  value = var.use_spot_fleet ? try(data.aws_instances.fleet_instance[0].public_ips[0], "pending — re-run 'terraform apply' or 'terraform refresh' once the fleet request is fulfilled") : local.simple_public_ip
}

output "dcv_url" {
  value = var.use_spot_fleet ? try("https://${data.aws_instances.fleet_instance[0].public_ips[0]}:8443", "pending") : "https://${local.simple_public_ip}:8443"
}
