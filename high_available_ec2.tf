
/* Create a custom VPC , custom_VPC, with CIDR block 10.0.0.0/16. The VPC should enable
DNS hostnames for EC2 instances created in the VPC
*/
resource "aws_vpc" "custom_VPC" {
  cidr_block       = "10.0.0.0/16"
  enable_dns_support = "true"
  enable_dns_hostnames   =  true
    tags = {
    Name = "custom_VPC"
  }
}

/*Create an Internet Gateway and attach it to the VPC, use the name tag IGWcustom_
VPC.*/

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.custom_VPC.id

  tags = {
    Name = "IGW-custom_VPC"
  }
}

/* 
Create two Public subnets with the names Public_Subnet1 and Public_Subnet2 in two
different Availability Zones, US-east-1a and us-east-1B
*/
# create the first public subnet in  us-east-2
resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.custom_VPC.id
  availability_zone = "us-east-2a"
  cidr_block = "10.0.10.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "public subnet 1"
  }
}

# create the second public subnet in  us-east-2

resource "aws_subnet" "subnet2" {
  vpc_id     = aws_vpc.custom_VPC.id
  availability_zone = "us-east-2b"
  cidr_block = "10.0.20.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "public subnet 2"
  }
}


/* 
Create a route table for these subnets. The route table must allow access to the internet.
Use the name Public_RT.
*/

resource "aws_route_table" "RT" {
  vpc_id = aws_vpc.custom_VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }


  tags = {
    Name = "Public_RT"
  }
}

# Route table association 
resource "aws_route_table_association" "Public1" {
  depends_on     = [aws_subnet.subnet1]
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.RT.id
}


resource "aws_route_table_association" "Public2" {
  depends_on     = [aws_subnet.subnet2]
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.RT.id
}

/* 
Create two Private subnets in the same AZs as above (1a and 1b) with the names,
Private_Subnet1 and Private_Subnet2.
*/

resource "aws_subnet" "subnet3" {
  vpc_id     = aws_vpc.custom_VPC.id
  availability_zone = "us-east-2a"
  cidr_block = "10.0.100.0/24"

  tags = {
    Name = "Private_Subnet1"
  }
}

# create the second public subnet in  us-east-2

resource "aws_subnet" "subnet4" {
  vpc_id     = aws_vpc.custom_VPC.id
  availability_zone = "us-east-2b"
  cidr_block = "10.0.200.0/24"

  tags = {
    Name = "Private_Subnet2"
  }
}
# Task 2 : Create Two NAT Gateways
###################################Task 2 ##############################################################
########################################################################################################
# Create two elastic IP addresses, EIP1 and EIP2

resource "aws_eip" "EIP1" {
  domain   = "vpc"
tags = {
    Name = "EIP1"
  }
}

resource "aws_eip" "EIP2" {
    
  domain   = "vpc"
  tags = {
    Name = "EIP1"
  }
}


/* Create two public NAT Gateways (NATGW1 and NATGW2) in availability zones (AZ) useast-
1a and another in us-east-1b.
*/

resource "aws_nat_gateway" "NATGW1" {
  allocation_id = aws_eip.EIP1.id
  subnet_id     = aws_subnet.subnet1.id

  tags = {
    Name = "NATGW1"
  }

}

resource "aws_nat_gateway" "NATGW2" {
  allocation_id = aws_eip.EIP2.id
  subnet_id     = aws_subnet.subnet2.id

  tags = {
    Name = "NATGW2"
  }

}

/* 
Create two separate route tables for the private subnets with the name
Private_RT_1 and Private_RT_2.
*/

resource "aws_route_table" "Private_RT_1" {
  vpc_id = aws_vpc.custom_VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.NATGW1.id
  }


  tags = {
    Name = "Private_RT_1"
  }
}

resource "aws_route_table" "Private_RT_2" {
  vpc_id = aws_vpc.custom_VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.NATGW2.id
  }


  tags = {
    Name = "Private_RT_2"
  }
}


# Route table association 
resource "aws_route_table_association" "Private1" {
  depends_on     = [aws_subnet.subnet3]
  subnet_id      = aws_subnet.subnet3.id
  route_table_id = aws_route_table.Private_RT_1.id
}


resource "aws_route_table_association" "Private2" {
  depends_on     = [aws_subnet.subnet4]
  subnet_id      = aws_subnet.subnet4.id
  route_table_id = aws_route_table.Private_RT_2.id
}

# Task 3 : Create Two Security Groups
/* Create 2 security groups WebSG (allows HTTP inbound and all traffic outbound) and
ALBSG (allows HTTP inbound and all traffic outbound)
*/

# create security group WebSG


resource "aws_security_group" "WebSG" {
  name        = "allow_http"
  description = "Allow http inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.custom_VPC.id

  tags = {
    Name = "WebSG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv4" {
  security_group_id = aws_security_group.WebSG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.WebSG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# create security group ALBSG


resource "aws_security_group" "ALBSG" {
  name        = "allow_http2"
  description = "Allow http inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.custom_VPC.id

  tags = {
    Name = "ALBSG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow2_http_ipv4" {
  security_group_id = aws_security_group.ALBSG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "allow2_all_traffic_ipv4" {
  security_group_id = aws_security_group.ALBSG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

##################################TASK 4#########################################
#################################################################################
/*
Task 4 : Create an instance profile that will use an IAM Role to allow the instances to connect
to SSM:
*/

# IAM Role for EC2 (SSM access)
resource "aws_iam_role" "ec2_ssm_role" {
  name = "EC2_SSM"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach correct SSM policy 
resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance Profile (this is what EC2 uses)
resource "aws_iam_instance_profile" "lt_profile" {
  name = "LT_Profile"
  role = aws_iam_role.ec2_ssm_role.name
}

# Task 5 : Create High Availability using an ApplicaJon Load Balancer:
##########################################Task 5#######################################
#######################################################################################

resource "aws_lb_target_group" "WebTG" {
  name     = "WebTG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.custom_VPC.id

    tags = {
    name ="WebTG"
  }
}


resource "aws_lb" "WebALB" {
  name               = "WebALB"
  internal           = false
  load_balancer_type = "application"
  enable_deletion_protection = false
  security_groups    = [aws_security_group.ALBSG.id]
  subnets            = [aws_subnet.subnet1.id , aws_subnet.subnet2.id]


  tags = {
    Environment = "production"
  }
}

# Create the ALB listener for Port 80 HTTP with a forwarding rule to WebTG and link the listener to the ALB

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.WebALB.arn

  port     = 80
  protocol = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.WebTG.arn
  }
}

########################################TASK 6########################################
######################################################################################
/*
Task 6 : Create a launch template and an auto scaling group to be integrated with the ALB
and take care of creaJng and terminaJng instances as required
*/


resource "aws_launch_template" "WebLT" {
  name = "Web_Launch_Template"

  block_device_mappings {
    device_name = "/dev/sdf"

    ebs {
      volume_size = 8
    }
  }


  iam_instance_profile {
    name = aws_iam_instance_profile.lt_profile.name
  }

  image_id = "ami-0ea1cddefe0c4aed5"

  instance_type = "t2.micro"
  instance_initiated_shutdown_behavior = "terminate"

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  monitoring {
    enabled = true
  }


  vpc_security_group_ids = [aws_security_group.WebSG.id]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "Web_App_Tier"
    }
  }

  user_data = filebase64("${path.module}/web.sh")
}



resource "aws_autoscaling_group" "ASG" {
  vpc_zone_identifier = [
  aws_subnet.subnet3.id,
  aws_subnet.subnet4.id
]
  desired_capacity   = 2
  max_size           = 4
  min_size           = 1


# This line links the Auto Scaling group to the ALB through the WebTG target group
 target_group_arns = ["${aws_lb_target_group.WebTG.arn}"]

  launch_template {
    id      = aws_launch_template.WebLT.id
    version = "$Latest"
  }
}

# Output the DNS hostname of the ALB to be used to test the application

output "alb_dns" {
  value=aws_lb.WebALB.dns_name
}
