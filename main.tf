resource "aws_security_group" "ros2_sg" {
  name        = "ros2-robotics-sg"
  description = "SSH and NICE DCV access for ROS2 robotics instance"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  ingress {
    description = "DCV Access"
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.instance_name}-sg"
  }
}

locals {
  provision_script = templatefile("${path.module}/scripts/provision.sh.tftpl", {})

  user_data = templatefile("${path.module}/scripts/bootstrap.sh.tftpl", {
    provision_script = local.provision_script
  })
}

resource "aws_instance" "ros2_robotics" {
  count = var.use_spot_fleet ? 0 : 1

  ami           = var.ami_id
  instance_type = var.instance_type
  # No key pair

  vpc_security_group_ids = [aws_security_group.ros2_sg.id]

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = var.root_volume_type
  }

  user_data = local.user_data

  tags = {
    Name = var.instance_name
  }
}

# --- Spot Fleet mode ---
# Mirrors the manual "Create Spot Fleet request" console flow:
# same AMI/storage/SG, no key pair, target capacity 1, spread across
# all AZs in the default VPC, price-capacity-optimized allocation,
# multiple acceptable instance types, one-time fulfillment (no
# automatic replacement on interruption).

resource "aws_spot_fleet_request" "ros2_fleet" {
  count = var.use_spot_fleet ? 1 : 0

  # References AWS's own default Spot Fleet service role — the same
  # one the console auto-creates the first time you submit a Spot
  # Fleet request.
  iam_fleet_role                       = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-ec2-spot-fleet-tagging-role"
  target_capacity                      = var.spot_fleet_target_capacity
  allocation_strategy                  = var.spot_fleet_allocation_strategy
  fleet_type                           = "request" # one-time fulfillment — no auto-replacement on interruption
  terminate_instances_with_expiration  = true
  wait_for_fulfillment                 = true

  dynamic "launch_specification" {
    for_each = setproduct(var.spot_fleet_instance_types, keys(data.aws_subnet.selected))
    content {
      ami                         = var.ami_id
      instance_type               = launch_specification.value[0]
      subnet_id                   = launch_specification.value[1]
      vpc_security_group_ids      = [aws_security_group.ros2_sg.id]
      associate_public_ip_address = true
      user_data                   = base64encode(local.user_data)

      root_block_device {
        volume_size = var.root_volume_size
        volume_type = var.root_volume_type
      }

      tags = {
        Name = var.instance_name
      }
    }
  }
}
