provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
	tags {
    Name = "Matthew"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "10.0.1.0/24"

  tags {
    Name = "public"
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "main"
  }
}

resource "aws_route_table" "direct_to_internet" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
  }

  tags {
    Name = "main"
  }
}

resource "aws_route_table_association" "public_out" {
  subnet_id      = "${aws_subnet.public.id}"
  route_table_id = "${aws_route_table.direct_to_internet.id}"
}

resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all inbound traffic"
	vpc_id      = "${aws_vpc.main.id}"

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "allow_all"
  }
}

resource "aws_eip" "ip" {
  instance = "${aws_instance.example.id}"
	vpc      = "true"
}

resource "aws_instance" "example" {
  ami           = "ami-efd0428f"
  instance_type = "t2.micro"
	key_name      = "${var.keypair}"
	subnet_id     = "${aws_subnet.public.id}"
	vpc_security_group_ids = ["${aws_security_group.allow_all.id}"]
}
