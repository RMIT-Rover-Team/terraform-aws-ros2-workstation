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

variable "use_spot_fleet" {
  description = "Launch via a Spot Fleet request instead of an on-demand instance."
  type        = bool
  default     = false
}

variable "spot_fleet_instance_types" {
  description = "Acceptable instance types for the Spot Fleet request, in preference order."
  type        = list(string)
  default     = ["g4dn.xlarge", "g5.xlarge", "g6.xlarge"]
}

variable "spot_fleet_target_capacity" {
  description = "Target capacity (number of instances) for the Spot Fleet request."
  type        = number
  default     = 1
}

variable "spot_fleet_allocation_strategy" {
  description = "Spot Fleet allocation strategy."
  type        = string
  default     = "priceCapacityOptimized"
}

variable "allowed_cidr" {
  description = "CIDR allowed for inbound SSH/DCV access. WARNING: 0.0.0.0/0 is open to the whole internet."
  type        = string
  default     = "0.0.0.0/0"
}
