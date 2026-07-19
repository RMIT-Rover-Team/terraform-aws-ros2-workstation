aws_region       = "ap-southeast-2"
# ami_id           = "ami-0319dc78bfd3b0412"
ami_id           = "ami-09f8c73caaf176d07"
instance_type    = "g4dn.xlarge"
instance_name    = "ROS2_Robotics"
root_volume_size = 120
root_volume_type = "gp3"
allowed_cidr     = "0.0.0.0/0"  # TODO: replace with your IP/32 before applying

# Spot Fleet mode — multi-instance-type, multi-AZ (see README "Spot Fleet")
use_spot_fleet                 = true
spot_fleet_instance_types      = ["g4dn.xlarge", "g5.xlarge", "g6.xlarge"]
spot_fleet_target_capacity     = 1
spot_fleet_allocation_strategy = "priceCapacityOptimized"
