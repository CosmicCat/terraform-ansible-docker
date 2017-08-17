resource "aws_db_subnet_group" "maria" {
  name       = "maria"
  subnet_ids = ["${aws_subnet.public1.id}", "${aws_subnet.public2.id}"]

  tags {
    Name = "My DB subnet group"
  }
}

resource "aws_db_instance" "maria" {
  allocated_storage    = 10
  storage_type         = "gp2"
  engine               = "mariadb"
  engine_version       = "10.1.23"
  instance_class       = "db.t2.micro"
  name                 = "mydb"
  username             = "test"
  password             = "supersecure"
  db_subnet_group_name = "${aws_db_subnet_group.maria.id}"
	vpc_security_group_ids = ["${aws_security_group.allow_all.id}"]
	publicly_accessible = true
	skip_final_snapshot = true
}

output "maria_endpoint" {
  value = "${aws_db_instance.maria.address}"
}