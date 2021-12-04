#!/bin/bash
yum install java-1.8.0-openjdk.x86_64 -y
mkdir /home/ec2-user/ES
cd /home/ec2-user/ES
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.9.2-x86_64.rpm
rpm -ivh elasticsearch-7.9.2-x86_64.rpm
sed -i 's/-Xm.*1g/-Xms512m/g' /etc/elasticsearch/jvm.options
