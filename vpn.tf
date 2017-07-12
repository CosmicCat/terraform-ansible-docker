resource "aws_eip" "vpn_ip" {
  instance = "${aws_instance.vpn_server.id}"
	vpc      = "true"
}

resource "aws_instance" "vpn_server" {
  ami           = "ami-0b5e4272"
  instance_type = "t2.micro"
	key_name      = "${var.keypair}"
	subnet_id     = "${aws_subnet.public.id}"
	vpc_security_group_ids = ["${aws_security_group.allow_all.id}"]

  tags {
    type = "vpn_server"
  }
}
