create database if not exists `test`;

use test;

CREATE TABLE IF NOT EXISTS `users` (
    id int NOT NULL AUTO_INCREMENT,
    name VARCHAR(20) NOT NULL,
    age INT NOT NULL,
    PRIMARY KEY(id));

insert into users
(name, age)
VALUES
    ('Alice', 20),
    ('Bob', 25),
    ('John', 30);

