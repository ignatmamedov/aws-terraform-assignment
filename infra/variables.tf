variable "aws_region" {
  default = "us-east-1"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "vpc_name" {
  default = "exam_main_vpc"
}

variable "subnets" {
  type = map(object({
    cidr = string
    az   = string
    name = string
  }))
  default = {
    subnet_1 = { cidr = "10.0.1.0/24", az = "us-east-1a", name = "exam_subnet_1" }
    subnet_2 = { cidr = "10.0.2.0/24", az = "us-east-1b", name = "exam_subnet_2" }
  }
}

variable "internet_gateway_name" {
  default = "exam_internet_gateway"
}

variable "route_table_name" {
  default = "exam_route_table"
}

variable "security_group_name" {
  default = "exam_security_group"
}

variable "ec2_ami" {
  default = "ami-04b4f1a9cf54c11d0"
}

variable "ec2_instance_type" {
  default = "t2.micro"
}

variable "ec2_key_pair" {
  default = "saxion_imamedov"
}

variable "ec2_instance_name" {
  default = "exam_ec2_instance"
}

variable "user_data_file" {
  default = "install_docker.sh"
}

variable "db_name" {
  default = "postgres"
}

variable "db_user" {
  default = "postgres"
}

variable "db_password" {
  default = "88005553535"
}

variable "dt_username" {
  default = "gitlab+deploy-token-7711230"
}

variable "dt_password" {
  default = "gldt-bNQg1UY8z5Wx5_TT21g-"
}

variable "container_url" {
  default = "registry.gitlab.com/saxionnl/hbo-ict/2.3-devops/2024-2025/exam-regular/15/backend:latest"
}

variable "app_key" {
  default = "base64:yqgFFzksV+C09W0+m69EFIaQOApHZ0knT6+kNZiidsE="
}

variable "app_name" {
  default = "thermometer"
}