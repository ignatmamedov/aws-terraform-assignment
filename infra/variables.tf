variable "aws_region" {
  default = "us-east-1"
}

variable "rds_subnet_group_name" {
  default = "exam-rds-subnet-group"
}

variable "rds_identifier" {
  default = "exam-postgres"
}

variable "alb_name" {
  default = "exam-alb"
}

variable "target_group_name" {
  default = "exam-target-group"
}

variable "launch_template_name" {
  default = "exam-launch-template"
}

variable "autoscaling_policy_name" {
  default = "cpu-utilization-policy"
}

variable "load_balancer_tag" {
  default = "exam-load-balancer"
}

variable "internet_gateway_name" {
  default = "exam_internet_gateway"
}

variable "route_table_name" {
  default = "exam_route_table"
}

variable "security_group_prefix" {
  default = "exam_security_group"
}

variable "app_name" {
  default = "thermometer"
}

variable "ec2_instance_name" {
  default = "exam_ec2_instance"
}

variable "user_data_file" {
  default = "install_docker.sh"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "vpc_name" {
  default = "exam_main_vpc"
}

variable "private_subnets" {
  type = map(object({
    cidr = string
    az = string
    name = string
  }))
  default = {
    subnet_1 = { cidr = "10.0.1.0/24", az = "us-east-1a", name = "private-subnet-1" }
    subnet_2 = { cidr = "10.0.2.0/24", az = "us-east-1b", name = "private-subnet-2" }
  }
}

variable "public_subnets" {
  type = map(object({
    cidr = string
    az   = string
    name = string
  }))
  default = {
    subnet_1 = { cidr = "10.0.3.0/24", az = "us-east-1a", name = "public-subnet-1" }
    subnet_2 = { cidr = "10.0.4.0/24", az = "us-east-1b", name = "public-subnet-2" }
  }
}

variable "ec2_ami" {
  default = "ami-04b4f1a9cf54c11d0"
}

variable "ec2_instance_type" {
  default = "t3.micro"
}

variable "ec2_key_pair" {
  type = string
}

variable "db_name" {
  type = string
}

variable "db_user" {
  type = string
}

variable "db_password" {
  type = string
  sensitive = true
}

variable "dt_username" {
  type = string
}

variable "dt_password" {
  type = string
  sensitive = true
}

variable "container_url" {
  type = string
}

variable "app_key" {
  type = string
  sensitive = true
}

variable "ec2_password" {
  type = string
  sensitive = true
}
variable "env" {
  type = string
}