#!/bin/bash
yum update -y
yum install -y httpd24 php70 php70-gd php70-imap php70-mbstring php70-mysqlnd php70-opcache php70-pdo php70-pecl-apcu php70-zip
service httpd start
chkconfig httpd on
aws s3 cp s3://vctfbootstrap/limesurvey/limesurvey2.65.3.zip limesurvey2.65.3.zip
unzip limesurvey2.65.3.zip 
mv limesurvey/ /var/www/html/limesurvey
chmod 777 -R /var/www/html
sed -i -e 's#DocumentRoot "/var/www/html"#DocumentRoot "/var/www/html/limesurvey"#g' /etc/httpd/conf/httpd.conf
sed -i -e 's#Directory "/var/www/html"#Directory "/var/www/html/limesurvey"#g' /etc/httpd/conf/httpd.conf
service httpd restart
cp /var/www/html/limesurvey/application/config/config-sample-mysql.php /var/www/html/limesurvey/application/config/config.php
sed -i -e "s/localhost/${rdsendpoint}/g" /var/www/html/limesurvey/application/config/config.php
sed -i -e "s/'root'/'limesurveyadmin'/g" /var/www/html/limesurvey/application/config/config.php
sed -i -e "s/''/'sTty58..sMwLxZnm'/g" /var/www/html/limesurvey/application/config/config.php
/usr/bin/php -f /var/www/html/limesurvey/application/commands/console.php install limeadmin 1sag45eGWRE54$ Admin surveyadmin@virtualclarity.com
echo "script complete"
