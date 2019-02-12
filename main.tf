data "terraform_remote_state" "network" {
  backend = "atlas"

  config {
    name = "${var.org}/${var.workspace_name}"
  }
}

provider "aws" {
  region = "${data.terraform_remote_state.network.region}"  
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "web" {
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"
  subnet_id = "${data.terraform_remote_state.network.research_subnet_id}"

  tags {
    Name = "Research Instance"
  }
}

module "ec2_cluster" {
  source  = "app.terraform.io/aharness-org/ec2-instance/aws"
  version = "1.14.0"

  name                   = "my-consumer-cluster"
  instance_count         = 2

  ami                    = "${data.aws_ami.ubuntu.id}"
  instance_type          = "t2.micro"
  monitoring             = true
# "${data.terraform_remote_state.vpc.subnet_id}"
# vpc_security_group_ids = ["${module.vpc.default_security_group_id}"]
# subnet_id              = "${element(module.vpc.public_subnets, 0)}"
  vpc_security_group_ids = ["${data.terraform_remote_state.vpc.default_security_group_id}"]
  subnet_id              = "${element(data.terraform_remote_state.vpc.public_subnets, 0)}"
  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

/*module "vpc" {
  source  = "app.terraform.io/aharness-org/vpc/aws"
  version = "0.9.1"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1f"]
  private_subnets = ["10.0.1.0/24"]
  public_subnets  = ["10.0.101.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = true

  tags = {
    Terraform = "true"
    Environment = "dev"
  }

}
*/

data "terraform_remote_state" "vpc" {
  backend = "atlas"
  config {
    name = "aharness-org/Producer-Repo"
  }
}

/*resource "aws_instance" "foo" {
  # ...
  subnet_id = "${data.terraform_remote_state.vpc.subnet_id}"
}
*/