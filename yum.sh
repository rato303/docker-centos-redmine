#!/bin/sh

EPEL_URL http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm

rpm -Uvh ${EPEL_URL}
yum groupinstall -y "Development Tools"
yum install -y openssl-devel readline-devel zlib-devel curl-devel libyaml-devel
yum install -y mysql-server mysql-devel
yum install -y httpd httpd-devel
yum install -y ImageMagick ImageMagick-devel ipa-pgothic-fonts
yum install -y python-setuptools
yum update -y
