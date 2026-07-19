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
  ami           = var.ami_id
  instance_type = var.instance_type
  # No key pair — matches "Proceed without a key pair" in the manual setup.
  # SSH access will only work if you set up password auth or SSM instead.

  vpc_security_group_ids = [aws_security_group.ros2_sg.id]

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = var.root_volume_type
  }

  user_data = local.user_data

  dynamic "instance_market_options" {
    for_each = var.use_spot_instance ? [1] : []
    content {
      market_type = "spot"
      spot_options {
        max_price                      = var.spot_max_price
        spot_instance_type             = "one-time"
        instance_interruption_behavior = "terminate"
      }
    }
  }

  tags = {
    Name = var.instance_name
  }
}
