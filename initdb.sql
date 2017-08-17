create database vacasa;

use vacasa;

create table users (
  uid int,
  first_name varchar(30),
  last_name varchar(30),
  phone varchar(15),
  active tinyint(1),
  date_created date
);

load data local infile 'db.dat' into table users;
