variable "INSTANCE_USERNAME" {
  default = "ubuntu"
}

variable "AWS_ACCESS_KEY" {
}

variable "AWS_SECRET_KEY" {
}

variable "AWS_REGION" {
}

variable "AMI" {
}

variable "MYIP" {
  type = list
}

variable "PORT_8080"{
  type = number
}

variable "PORT_80" {
  type = number
}