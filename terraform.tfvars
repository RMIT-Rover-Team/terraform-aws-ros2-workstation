aws_region       = "ap-southeast-2"
ami_id           = "ami-0319dc78bfd3b0412"
instance_type    = "g4dn.xlarge"
instance_name    = "ROS2_Robotics"
root_volume_size = 120
root_volume_type = "gp3"
allowed_cidr     = "0.0.0.0/0"  # TODO: replace with your IP/32 before applying

# Spot instance (optional) — see README "Spot instances" section.
# use_spot_instance = true
# spot_max_price    = "0.50"
