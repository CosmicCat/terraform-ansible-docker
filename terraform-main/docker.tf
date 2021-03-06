resource "aws_eip" "manager-ip" {
  instance = "${aws_instance.docker-manager.id}"
	vpc      = "true"
}

resource "aws_instance" "docker-manager" {
  ami           = "${var.docker_ami}"
  instance_type = "t2.micro"
	key_name      = "${var.keypair}"
	subnet_id     = "${aws_subnet.public1.id}"
	vpc_security_group_ids = ["${aws_security_group.allow_all.id}"]
}

resource "aws_eip" "worker-ip1" {
  instance = "${aws_instance.docker-worker1.id}"
	vpc      = "true"
}

resource "aws_instance" "docker-worker1" {
  ami           = "${var.docker_ami}"
  instance_type = "t2.micro"
	key_name      = "${var.keypair}"
	subnet_id     = "${aws_subnet.public2.id}"
	vpc_security_group_ids = ["${aws_security_group.allow_all.id}"]
}

resource "aws_eip" "worker-ip2" {
  instance = "${aws_instance.docker-worker2.id}"
	vpc      = "true"
}

resource "aws_instance" "docker-worker2" {
  ami           = "${var.docker_ami}"
  instance_type = "t2.micro"
	key_name      = "${var.keypair}"
	subnet_id     = "${aws_subnet.public2.id}"
	vpc_security_group_ids = ["${aws_security_group.allow_all.id}"]
}

resource "aws_elb" "docker-elb" {
  name               = "docker-elb"
	subnets = ["${aws_subnet.public1.id}", "${aws_subnet.public1.id}"]
	security_groups = ["${aws_security_group.allow_all.id}"]

  listener {
    instance_port     = 8080
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:8080/"
    interval            = 30
  }

  instances                   = ["${aws_instance.docker-manager.id}", "${aws_instance.docker-worker1.id}", "${aws_instance.docker-worker2.id}"]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags {
    Name = "docker-elb"
  }
}

output "docker_manager_ip" {
  value = "${aws_eip.manager-ip.public_ip}"
}

output "docker_worker_ip1" {
  value = "${aws_eip.worker-ip1.public_ip}"
}

output "docker_worker_ip2" {
  value = "${aws_eip.worker-ip2.public_ip}"
}

output "elb_endpoint" {
  value = "${aws_elb.docker-elb.dns_name}"
}