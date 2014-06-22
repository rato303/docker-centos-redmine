#!/bin/sh

RUBY_VERSION=ruby-2.0.0-p451
REDMINE_VERSION=redmine-2.5.1
RUBY_URL=http://cache.ruby-lang.org/pub/ruby/2.0/ruby-2.0.0-p451.tar.gz
REDMINE_URL=http://www.redmine.org/releases/redmine-2.5.1.tar.gz
REDMINE_DB_NAME=redmine
REDMINE_DB_USER_NAME=redmine
REDMINE_DB_PW=redmine

yum install -y sudo
yum install -y passwd
yum install -y openssh-server
yum install -y openssh-clients
rpm -Uvh ${EPEL_URL}
yum groupinstall -y "Development Tools"
yum install -y openssl-devel readline-devel zlib-devel curl-devel libyaml-devel
yum install -y mysql-server mysql-devel
yum install -y httpd httpd-devel
yum install -y ImageMagick ImageMagick-devel ipa-pgothic-fonts
yum install -y python-setuptools
yum update -y

/usr/bin/ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key -C '' -N ''
/usr/bin/ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -C '' -N ''
sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config
sed -ri 's/#UsePAM no/UsePAM no/g' /etc/ssh/sshd_config

useradd worker
passwd -f -u worker
mkdir -p /home/worker/.ssh
chmod 700 /home/worker/.ssh
cp -rf /root/authorized_keys /home/worker/.ssh/authorized_keys
chmod 600 /home/worker/.ssh/authorized_keys
chown -R worker /home/worker/

echo "worker ALL=(ALL) ALL" >> /etc/sudoers.d/worker

easy_install supervisor
echo_supervisord_conf > /etc/supervisord.conf
echo "[include]" >> /etc/supervisord.conf
echo "files = supervisord/conf/*.conf" >> /etc/supervisord.conf
mkdir -p /etc/supervisord/conf
cp -rf /root/service.conf /etc/supervisord/conf/service.conf

curl -o /usr/local/src/${RUBY_VERSION}.tar.gz $RUBY_URL
tar xvf /usr/local/src/${RUBY_VERSION}.tar.gz -C /usr/local/src
/usr/local/src/$RUBY_VERSION/configure --disable-install-doc
make
make install
gem install bundler --no-rdoc --no-ri

cp -rf /root/my.cnf /etc/my.cnf

chkconfig mysqld on

service mysqld start

mysql -uroot -e "create database ${REDMINE_DB_NAME} default character set utf8;"
mysql -uroot -e "grant all on ${REDMINE_DB_NAME}.* to ${REDMINE_DB_USER_NAME}@localhost identified by '${REDMINE_DB_PW}';"
mysql -uroot -e "flush privileges;"

curl -o /var/lib/${REDMINE_VERSION}.tar.gz ${REDMINE_URL}
tar xvf /var/lib/${REDMINE_VERSION}.tar.gz -C /var/lib
rm -f /var/lib/${REDMINE_VERSION}.tar.gz
mv /var/lib/${REDMINE_VERSION} /var/lib/redmine
mv -f /root/database.yml /var/lib/redmine/config/database.yml
sed -ri "s/%%REDMINE_DB_NAME%%/${REDMINE_DB_NAME}/" /var/lib/redmine/config/database.yml
sed -ri "s/%%REDMINE_DB_USER_NAME%%/${REDMINE_DB_USER_NAME}/" /var/lib/redmine/config/database.yml
sed -ri "s/%%REDMINE_DB_PW%%/${REDMINE_DB_PW}/" /var/lib/redmine/config/database.yml

service mysqld start
cd /var/lib/redmine
bundle install --without development test
bundle exec rake generate_secret_token
RAILS_ENV=production bundle exec rake db:migrate

gem install passenger --no-rdoc --no-ri
passenger-install-apache2-module -a
passenger-install-apache2-module --snippet > /tmp/snippet
cat /tmp/snippet /root/passenger.conf > /etc/httpd/conf.d/passenger.conf

chkconfig httpd on

chown -R apache:apache /var/lib/redmine

ln -s /var/lib/redmine/public /var/www/html/redmine

service httpd configtest
