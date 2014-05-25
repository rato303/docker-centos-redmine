#/bin/sh
service mysqld start
cd /var/lib/redmine
bundle install --without development test
bundle exec rake generate_secret_token
RAILS_ENV=production bundle exec rake db:migrate
