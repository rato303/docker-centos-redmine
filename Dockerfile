FROM centos
MAINTAINER Toshiya Kimura

ENV RUBY_VERSION ruby-2.0.0-p451
ENV REDMINE_VERSION redmine-2.5.1
ENV EPEL_URL http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
ENV RUBY_URL http://cache.ruby-lang.org/pub/ruby/2.0/ruby-2.0.0-p451.tar.gz
ENV REDMINE_URL http://www.redmine.org/releases/redmine-2.5.1.tar.gz
ENV REDMINE_DB_NAME redmine
ENV REDMINE_DB_USER_NAME redmine
ENV REDMINE_DB_PW redmine

RUN rpm -Uvh $EPEL_URL
RUN yum groupinstall -y "Development Tools"
RUN yum install -y openssl-devel readline-devel zlib-devel curl-devel libyaml-devel
RUN yum install -y mysql-server mysql-devel
RUN yum install -y httpd httpd-devel
RUN yum install -y ImageMagick ImageMagick-devel ipa-pgothic-fonts
RUN yum update -y

RUN curl -o /usr/local/src/$RUBY_VERSION.tar.gz $RUBY_URL
RUN tar xvf /usr/local/src/$RUBY_VERSION.tar.gz -C /usr/local/src
RUN /usr/local/src/$RUBY_VERSION/configure --disable-install-doc
RUN make
RUN make install
RUN gem install bundler --no-rdoc --no-ri

ADD my.cnf /etc/my.cnf
RUN chkconfig mysqld on

ADD redmine_mysql.sh /root/redmine_mysql.sh
RUN chmod +x /root/redmine_mysql.sh
RUN sh /root/redmine_mysql.sh $REDMINE_DB_NAME $REDMINE_DB_USER_NAME $REDMINE_DB_PW

RUN curl -o /var/lib/$REDMINE_VERSION.tar.gz $REDMINE_URL
RUN tar xvf /var/lib/$REDMINE_VERSION.tar.gz -C /var/lib
RUN rm -f /var/lib/$REDMINE_VERSION.tar.gz
RUN mv /var/lib/$REDMINE_VERSION /var/lib/redmine
ADD database.yml /var/lib/redmine/config/database.yml
RUN sed -ri "s/%%REDMINE_DB_NAME%%/$REDMINE_DB_NAME/" /var/lib/redmine/config/database.yml
RUN sed -ri "s/%%REDMINE_DB_USER_NAME%%/$REDMINE_DB_USER_NAME/" /var/lib/redmine/config/database.yml
RUN sed -ri "s/%%REDMINE_DB_PW%%/$REDMINE_DB_PW/" /var/lib/redmine/config/database.yml
ADD redmine_rake.sh /root/redmine_rake.sh
RUN chmod +x /root/redmine_rake.sh
RUN sh /root/redmine_rake.sh

RUN gem install passenger --no-rdoc --no-ri
RUN passenger-install-apache2-module
ADD passenger.conf /etc/httpd/conf.d/passenger.conf

RUN service httpd start
RUN chkconfig httpd on

RUN chown -R apache:apache /var/lib/redmine

RUN ln -s /var/lib/redmine/public /var/www/html/redmine

RUN service httpd configtest
