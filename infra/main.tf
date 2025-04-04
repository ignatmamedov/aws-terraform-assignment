locals {
  vpc_name = "${var.vpc_name}_${var.env}"
  internet_gateway_name = "${var.internet_gateway_name}_${var.env}"
  route_table_name = "${var.route_table_name}_${var.env}"
  security_group_name = "${var.security_group_prefix}_${var.env}"
  rds_subnet_group_name = "${var.rds_subnet_group_name}-${var.env}"
  rds_identifier = "${var.rds_identifier}-${var.env}"
  alb_name = "${var.alb_name}-${var.env}"
  target_group_name = "${var.target_group_name}-${var.env}"
  launch_template_name = "${var.launch_template_name}-${var.env}-"
  autoscaling_policy_name = "${var.autoscaling_policy_name}-${var.env}"
  load_balancer_tag = "${var.load_balancer_tag}-${var.env}"
  container_url = "${var.container_url}:${var.env}"
}

provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "exam_main" {
  cidr_block = var.vpc_cidr
  instance_tenancy = "default"

  tags = {
    Name = local.vpc_name
  }
}

resource "aws_subnet" "exam_subnets" {
  for_each = var.subnets
  vpc_id = aws_vpc.exam_main.id
  cidr_block = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name = "${each.value.name}_${var.env}"
  }
}

resource "aws_internet_gateway" "exam_gw" {
  vpc_id = aws_vpc.exam_main.id

  tags = {
    Name = local.internet_gateway_name
  }
}

resource "aws_route_table" "exam_route_table" {
  vpc_id = aws_vpc.exam_main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.exam_gw.id
  }

  tags = {
    Name = local.route_table_name
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
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = [aws_security_group.exam_sg.id]
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
    Name = local.security_group_name
  }
}

resource "aws_db_subnet_group" "exam_rds_subnet_group" {
  name       = local.rds_subnet_group_name
  subnet_ids = [for subnet in aws_subnet.exam_subnets : subnet.id]

  tags = {
    Name = local.rds_subnet_group_name
  }
}

resource "aws_db_instance" "exam_rds" {
  identifier = local.rds_identifier
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
    Name = local.rds_identifier
  }
}

resource "aws_launch_template" "exam_lt" {
  name_prefix = local.launch_template_name
  image_id = var.ec2_ami
  instance_type = var.ec2_instance_type
  key_name = var.ec2_key_pair

  network_interfaces {
    associate_public_ip_address = false
    security_groups = [aws_security_group.exam_sg.id]
  }

  user_data = base64encode(templatefile(var.user_data_file, {
    dt_username = var.dt_username,
    dt_password = var.dt_password,
    db_host = aws_db_instance.exam_rds.address,
    db_port = aws_db_instance.exam_rds.port,
    db_name = var.db_name,
    db_user = var.db_user,
    db_password = var.db_password,
    container_url = local.container_url,
    app_key = var.app_key,
    app_name = var.app_name
  }))
}

resource "aws_autoscaling_group" "exam_asg" {
  vpc_zone_identifier = [for subnet in aws_subnet.exam_subnets : subnet.id]
  desired_capacity = 2
  min_size = 2
  max_size = 4
  health_check_type  = "EC2"
  termination_policies = ["OldestInstance"]
  launch_template {
    id = aws_launch_template.exam_lt.id
    version = "$Latest"
  }
}

resource "aws_autoscaling_policy" "cpu_scaling_policy" {
  name = local.autoscaling_policy_name
  autoscaling_group_name = aws_autoscaling_group.exam_asg.name
  adjustment_type = "ChangeInCapacity"
  scaling_adjustment = 1
  cooldown  = 60
  policy_type = "SimpleScaling"
}

resource "aws_lb" "exam_alb" {
  name = local.alb_name
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.exam_sg.id]
  subnets = [for subnet in aws_subnet.exam_subnets : subnet.id]

  tags = {
    Name = local.load_balancer_tag
  }
}

resource "aws_lb_target_group" "exam_tg" {
  name = local.target_group_name
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

output "lb_dns" {
  value = aws_lb.exam_alb.dns_name
}

output "autoscaling_group_name" {
  value = aws_autoscaling_group.exam_asg.name
}