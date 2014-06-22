#/bin/sh
gem install passenger --no-rdoc --no-ri
passenger-install-apache2-module -a
passenger.conf /etc/httpd/conf.d/passenger.conf
passenger-install-apache2-module --snippet > /tmp/snippet
cat /tmp/snippet /etc/httpd/conf.d/passenger.conf > /etc/httpd/conf.d/passenger.conf
