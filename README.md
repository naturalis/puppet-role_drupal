puppet-role_drupal
===================

Puppet role definition for deployment of drupal software

Parameters
-------------
Sensible defaults for Naturalis in init.pp, extra_users_hash for additional SSH users. 
admin password will be reported during installation, when installation is done unattended then search in /var/log/syslog for the text:  Installation complete.  User name: admin  User password: <password here>
- configuredrupal             Main installation part, advised to be set to false after installation is complete, modules tend to be re-enabled during every puppet run. 
- dbpassword                  Drupal database password
- docroot                     Documentroot, match location with 'docroot' part of the instances parameter
- drupalversion               Drupal version
- drushversion                Drush version
- extra_users_hash            Hash for extra users passed through to base::users from the naturalis\puppet-base manifest, see example below.
- mysql_root_password         Root password for mysql server
- modules                     Array with modules to be enabled within the drupal installation
- cron                        Enable hourly cronjob for drupal installation. 
- CKEditor                    Enable download of CKEditor, requires module: ckeditor
- CKEditorURL                 Download URL for CKEditor 
- instances                   Apache vhost configuration array

```
role_drupalng::extra_users_hash:
  user1:
    comment: "Example user 1"
    shell: "/bin/zsh"
    ssh_key:
      type: "ssh-rsa"
      comment: "user1.soortenregister.nl"
      key: "AAAAB3sdfgsdfgzyc2EAAAABJQAAAIEArnZ3K6vJ8ZisdqPhsdfgsdf5gdKkpuf5rCqOgGphDrBt3ntT7+rWzjx39Im64CCoL+q6ZKgckEZMjGaOKcV+c77nCmSb8eqAM/4eltwj+OgJ5K5DVi1pUaWxR5IoeiulZK36DetVZJCGCkxxLopjSDFGAS234aPC13cLM0Qqfxk="
```


Classes
-------------
- role_drupal
- role_drupal::instances

Dependencies
-------------
- naturalis/base
- puppetlabs/mysql
- puppetlabs/apache2
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


Authors
-------------
Author Name <hugo.vanduijn@naturalis.nl>

