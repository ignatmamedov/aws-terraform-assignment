provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "exam_main" {
  cidr_block = var.vpc_cidr
  instance_tenancy = "default"

  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "exam_subnets" {
  for_each = var.subnets
  vpc_id = aws_vpc.exam_main.id
  cidr_block = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name = each.value.name
  }
}

resource "aws_internet_gateway" "exam_gw" {
  vpc_id = aws_vpc.exam_main.id

  tags = {
    Name = var.internet_gateway_name
  }
}

resource "aws_route_table" "exam_route_table" {
  vpc_id = aws_vpc.exam_main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.exam_gw.id
  }

  tags = {
    Name = var.route_table_name
  }
}

resource "aws_route_table_association" "exam_assoc" {
  for_each = aws_subnet.exam_subnets
  subnet_id = each.value.id
  route_table_id = aws_route_table.exam_route_table.id
}

resource "aws_security_group" "exam_sg" {
  vpc_id = aws_vpc.exam_main.id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.security_group_name
  }
}

resource "aws_db_subnet_group" "exam_rds_subnet_group" {
  name       = "exam-rds-subnet-group"
  subnet_ids = [for subnet in aws_subnet.exam_subnets : subnet.id]

  tags = {
    Name = "exam-rds-subnet-group"
  }
}

resource "aws_db_instance" "exam_rds" {
  identifier = "exam-postgres"
  engine = "postgres"
  engine_version = "17.4"
  instance_class = "db.c6gd.medium"
  allocated_storage = 20
  storage_type = "gp2"
  db_name = var.db_name
  username = var.db_user
  password = var.db_password
  db_subnet_group_name = aws_db_subnet_group.exam_rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.exam_sg.id]
  publicly_accessible = false
  skip_final_snapshot = true

  tags = {
    Name = "exam-postgres-db"
  }
}

resource "aws_launch_template" "exam_lt" {
  name_prefix = "exam-launch-template-"
  image_id = var.ec2_ami
  instance_type = var.ec2_instance_type
  key_name = var.ec2_key_pair

  network_interfaces {
    associate_public_ip_address = true
    security_groups = [aws_security_group.exam_sg.id]
  }

  user_data = base64encode(templatefile(var.user_data_file, {
    dt_username = var.dt_username,
    dt_password = var.dt_password
    db_host = aws_db_instance.exam_rds.address,
    db_port = aws_db_instance.exam_rds.port,
    db_name = var.db_name,
    db_user = var.db_user,
    db_password = var.db_password
    container_url = var.container_url
  }))
}

resource "aws_autoscaling_group" "exam_asg" {
  vpc_zone_identifier = [for subnet in aws_subnet.exam_subnets : subnet.id]
  desired_capacity = 2
  min_size = 2
  max_size = 4
  health_check_type  = "EC2"
  launch_template {
    id = aws_launch_template.exam_lt.id
    version = "$Latest"
  }
}

resource "aws_autoscaling_policy" "cpu_scaling_policy" {
  name = "cpu-utilization-policy"
  autoscaling_group_name = aws_autoscaling_group.exam_asg.name
  adjustment_type = "ChangeInCapacity"
  scaling_adjustment = 1
  cooldown  = 60
  policy_type = "SimpleScaling"
}

resource "aws_lb" "exam_alb" {
  name = "exam-alb"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.exam_sg.id]
  subnets = [for subnet in aws_subnet.exam_subnets : subnet.id]

  tags = {
    Name = "exam-load-balancer"
  }
}

resource "aws_lb_target_group" "exam_tg" {
  name = "exam-target-group"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.exam_main.id
  target_type = "instance"
  health_check {
    path = "/"
    interval = 30
    timeout = 5
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

resource "aws_autoscaling_attachment" "exam_asg_attach" {
  autoscaling_group_name = aws_autoscaling_group.exam_asg.name
  lb_target_group_arn = aws_lb_target_group.exam_tg.arn
}

resource "aws_lb_listener" "exam_listener" {
  load_balancer_arn = aws_lb.exam_alb.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.exam_tg.arn
  }
}

# output lb dns
output "lb_dns" {
  value = aws_lb.exam_alb.dns_name
}