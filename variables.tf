variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-southeast-2"
}

variable "ami_id" {
  description = "AMI ID for the instance"
  type        = string
  default     = "ami-0319dc78bfd3b0412"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "g4dn.xlarge"
}

variable "instance_name" {
  description = "Name tag for the instance"
  type        = string
  default     = "ROS2_Robotics"
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 120
}

variable "root_volume_type" {
  description = "Root volume type"
  type        = string
  default     = "gp3"
}

variable "use_spot_instance" {
  description = "Launch as a spot instance instead of on-demand"
  type        = bool
  default     = false
}

variable "spot_max_price" {
  description = "Max hourly price willing to pay for spot (USD). Leave null to default to the current on-demand price as the cap."
  type        = string
  default     = null
}

variable "allowed_cidr" {
  description = "CIDR allowed for inbound SSH/DCV access. WARNING: 0.0.0.0/0 is open to the whole internet."
  type        = string
  default     = "0.0.0.0/0"
}
