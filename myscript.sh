#!/bin/bash
sudo yum update -y
sudo yum install docker -y 
sudo systemctl start docker
sudo docker run -d -p 80:80 nginx