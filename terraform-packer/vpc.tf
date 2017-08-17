provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

resource "aws_vpc" "packer_main" {
  cidr_block = "10.0.0.0/16"
	enable_dns_hostnames = "true"

	tags {
    Name = "packer-main"
  }
}

resource "aws_subnet" "public1" {
  vpc_id     = "${aws_vpc.packer_main.id}"
  cidr_block = "10.0.1.0/24"
	availability_zone = "us-west-2a"

  tags {
    Name = "public"
  }
}

resource "aws_subnet" "public2" {
  vpc_id     = "${aws_vpc.packer_main.id}"
  cidr_block = "10.0.2.0/24"
	availability_zone = "us-west-2b"

  tags {
    Name = "public"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.packer_main.id}"

  tags {
    Name = "packer_igw"
  }
}

resource "aws_route_table" "direct_to_igw" {
  vpc_id = "${aws_vpc.packer_main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }

  tags {
    Name = "direct_internet"
  }
}

resource "aws_route_table_association" "public1_out" {
  subnet_id      = "${aws_subnet.public1.id}"
  route_table_id = "${aws_route_table.direct_to_igw.id}"
}

resource "aws_route_table_association" "public2_out" {
  subnet_id      = "${aws_subnet.public2.id}"
  route_table_id = "${aws_route_table.direct_to_igw.id}"
}

resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all traffic"
	vpc_id      = "${aws_vpc.packer_main.id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # terraform strips the egress allow all default rule because security - add it back
	egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags {
    Name = "allow_all"
  }
}

output "packer_sg" {
  value = "${aws_security_group.allow_all.id}"
}

output "packer_subnet" {
  value = "${aws_subnet.public1.id}"
}