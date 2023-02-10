variable "INSTANCE_USERNAME" {
  type = string
  default = "ubuntu"
}

variable "AWS_ACCESS_KEY" {
  type = string
}

variable "AWS_SECRET_KEY" {
  type = string
}

variable "AWS_REGION" {
  type = string
  default = "us-east-1"
}

variable "AMI" {
  type = string
  default = "ami-00874d747dde814fa"
}

variable "MYIP" {
  type = list
}

variable "port8080" {
  type = number
  default = 8080
}