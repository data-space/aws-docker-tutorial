### VARIABLES
###

variable "aws_region" {
  description = "AWS region to launch servers"
  default     = "us-east-2" # US East - Ohio
}

# Create this key pair in AWS
variable "aws_key_name" {
  description = "AWS key pair"
  default     = "datalab-ohio"
}

# Download your SSH private key file from AWS
variable "aws_key_file" {
  description = "AWS key file"
  default     = "/Users/david/Keys/datalab-ohio.pem"
}

variable "aws_instance_type" {
  description = "AWS instance type"
  default      = "t2.large"
}

variable "aws_ami" {
  description = "AWS AMI"
  default      = "ami-9cbf9bf9"
}

variable "aws_root_volume_type" {
  description = "Root device type"
  default      = "gp2"
}

variable "aws_root_volume_size" {
  description = "Root device size (GB)"
  default      = "50"
}
variable "aws_root_volume_dot" {  
  description = "Root device EBS volume: delete on terminate"
  default      = "true"
}

### CODE 
###

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region = "${var.aws_region}"
}

resource "aws_security_group" "datalab_test" {
  name = "datalab_test"
  #vpc_id = "${aws_vpc.datalake_vpc.id}"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["141.133.0.0/16"]
    ############# add your home IP address 
  }
  ingress { 
    from_port   = 8888
    to_port     = 8888
    protocol    = "tcp"
    cidr_blocks = ["141.133.0.0/16"]
    ############# add your home IP address 
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "test" {
  ami                    = "${var.aws_ami}"
  instance_type          = "${var.aws_instance_type}"
  key_name               = "${var.aws_key_name}"
  vpc_security_group_ids = ["${aws_security_group.datalab_test.id}"]
  tags {
    Name = "datalab-test"
  }
  root_block_device {
    delete_on_termination = "${var.aws_root_volume_dot}"
    volume_size = "${var.aws_root_volume_size}"
    volume_type = "${var.aws_root_volume_type}"
  }
  # Install Docker and docker-compose
  provisioner "remote-exec" {
    inline = [
      "sudo yum install -y yum-utils device-mapper-persistent-data lvm2",
      "sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo",
      "sudo yum install docker-ce -y",
      "sudo systemctl start docker",
      "sudo systemctl enable docker",
      "sudo yum install -y epel-release",
      "sudo yum install -y python-pip",
      "sudo pip install --upgrade pip",
      "sudo pip install docker-compose", 
      "sudo yum install git -y"
      ]  
    connection {
      type        = "ssh"
      user        = "centos"
      private_key = "${file("${var.aws_key_file}")}"
    }
  }
}

### OUTPUT
###

output "aws_key_file" {
  value = "${var.aws_key_file}"
}

output "public_ip" {
  value = ["${aws_instance.test.public_ip}"]
}
