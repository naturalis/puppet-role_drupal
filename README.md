puppet-role_drupal
===================

Puppet role definition for deployment of drupal software

Parameters
-------------
Sensible defaults for Naturalis in init.pp, extra_users_hash for additional SSH users. 
admin password will be reported during installation, when installation is done unattended then search in /var/log/syslog for the text:  Installation complete.  User name: admin  User password: <password here>

```
- configuredrupal             Main installation part, advised to be set to false after installation is complete. If set to true and a non working drupal installation is found ( for example due to incorrect module ) then a complete reinstallation of drupal including a complete db drop is initiated.
- enablessl                   Enable apache SSL modules, see SSL example
- dbpassword                  Drupal database password
- docroot                     Documentroot, match location with 'docroot' part of the instances parameter
- drupalversion               Drupal version
- drushversion                Drush version
- mysql_root_password         Root password for mysql server
- cron                        Enable hourly cronjob for drupal installation. 
- instances                   Apache vhost configuration array
```


example ssl enabled virtual hosts with http to https redirect.

```
role_drupal::enablessl: true
role_drupal::instances:
site-with-ssl.drupalsites.nl: 
  serveraliases: "*.drupalsites.nl"
  serveradmin: webmaster@drupalsites.nl
  port: 443
  priority: 10
  directories: 
  - options: -Indexes +FollowSymLinks +MultiViews
    path: /var/www/drupal
    allow_override: All
  docroot: /var/www/sisdrupal
  ssl: true
site-without-ssl.drupalsites.nl: 
  rewrites: 
  - rewrite_rule: 
    - ^(.*)$ https://site-with-ssl.drupalsites.nl/$1 [R,L]
  serveraliases: "*.drupalsites.nl"
  serveradmin: webmaster@drupalsites.nl
  port: 80
  docroot: /var/www/drupal
  priority: 5
```


Classes
-------------
- role_drupal
- role_drupal::instances

Dependencies
-------------
- puppetlabs/mysql
- puppetlabs/apache2
- puppetlabs/vcsrepo
- puppetlabs/concat
- binford2k/binford2k-drupal 0.0.4  <- forked@naturalis for mysql-php binding fix
- thias/php


Puppet code
```
class { role_drupal: }
```
Result
-------------
Working webserver with mysql and drupal installation. Additional module installation and hourly cronjobs are also installed by default.
Additional php modules: gd and apc are installed and pecl-apc is also configured so drupal upload status bars are allowed. 

Limitations
-------------
This module has been built on and tested against Puppet 3 and higher.


The module has been tested on:
- Ubuntu 12.04LTS
- Ubuntu 14.04LTS


Authors
-------------
Author Name <hugo.vanduijn@naturalis.nl>

