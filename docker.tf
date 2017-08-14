resource "aws_eip" "manager-ip" {
  instance = "${aws_instance.docker-manager.id}"
	vpc      = "true"
}

resource "aws_instance" "docker-manager" {
  ami           = "ami-6003e118"
  instance_type = "t2.micro"
	key_name      = "${var.keypair}"
	subnet_id     = "${aws_subnet.public1.id}"
	vpc_security_group_ids = ["${aws_security_group.allow_all.id}"]
}

resource "aws_eip" "worker-ip" {
  instance = "${aws_instance.docker-worker.id}"
	vpc      = "true"
}

resource "aws_instance" "docker-worker" {
  ami           = "ami-6003e118"
  instance_type = "t2.micro"
	key_name      = "${var.keypair}"
	subnet_id     = "${aws_subnet.public2.id}"
	vpc_security_group_ids = ["${aws_security_group.allow_all.id}"]
}
