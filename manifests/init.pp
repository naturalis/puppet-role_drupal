# == Class: role_drupal
#
# Full description of class role_drupal here.
#
# === Authors
#
# Author Name <hugo.vanduijn@naturalis.nl>
#
#
class role_drupal (
# General settings
  $admin_password               = randstr(),
  $packagename                  = 'drupal7',
  $enablessl                    = false,
  $enableletsencrypt            = false,
  $letsencrypt_email            = 'letsencypt@mydomain.me',
  $letsencrypt_version          = 'master',
  $letsencrypt_domains          = ['www.drupalsites.nl'],
  $letsencrypt_server           = 'https://acme-v01.api.letsencrypt.org/directory',
  $configuredrupal              = true,
  $docroot                      = '/var/www/drupal',
  $drupalversion                = '7.56',
  $updateall                    = false,                                   # all updates using drush up
  $updatesecurity               = true,                                    # only security updates
  $updatedrush                  = true,                                    # update drush and composer to latest version
  $drushversion                 = '8.x',
  $mysql_root_password          = 'rootpassword',
  $cron                         = true,
  $base_url                     = '',                                      # important when using SSL offloading!
  $testscriptsdir               = '/opt/repo/scripts',
#  PHP Settings
  $php_memory_limit             = '128M',
  $upload_max_filesize          = '2M',
  $post_max_size                = '8M',
  $ses_gc_maxlife               = 200000,
  $ses_cookie_life              = 2000000,
# Mysql Settings
  $mysql_large_indexes          = 'true',
  $mysql_innodb_large_prefix    = 'true',
  $mysql_innodb_file_format     = 'barracuda',
  $mysql_innodb_file_per_table  = 'true',
  $managedatabase               = true,
  $dbname                       = 'drupal',
  $dbuser                       = 'drupal',
  $dbpassword                   = 'drupal',
  $dbhost                       = 'localhost',
  $dbport                       = '',
  $dbdriver                     = 'mysql',
  $dbprefix                     = '',
  $dbcharset                    = 'utf8mb4',
  $dbcollation                  = 'utf8mb4_general_ci',

# sensu check settings
  $checks_defaults    = {
    interval      => 600,
    occurrences   => 3,
    refresh       => 60,
    handlers      => ['drupal_mailer','default'],
    subscribers   => ['appserver'],
    standalone    => true },

# Install profile settings
  $install_profile_userepo      = false,
  $install_profile              = 'standard',  # use standard for standard profile
  $install_profile_repo         = 'git@github.com:naturalis/drupal_naturalis_installation_profile.git',
  $install_profile_repoversion  = 'present',
  $install_profile_reposshauth  = false,
  $install_profile_repokey      = undef,
  $install_profile_repokeyname  = 'githubkey',
  $install_profile_repotype     = 'git',
  $instances                    = {'site.drupalsites.nl' => {
                                  'serveraliases'   => '*.drupalsites.nl',
                                  'docroot'         => '/var/www/drupal',
                                  'directories'     => [{ 'path' => '/var/www/drupal', 'options' => '-Indexes +FollowSymLinks +MultiViews', 'allow_override' => 'All' }],
                                  'port'            => 80,
                                  'serveradmin'     => 'webmaster@naturalis.nl',
                                  'priority'        => 10,
                                  },
                                },
# add rewrite block to instances to rewrite http to https
#
#                                 'rewrites'        => [{ 'rewrite_rule' => '^/?(.*) https://%{SERVER_NAME}/$1 [R,L]' }],
#
# Foreman yaml format:
#
#  rewrites:
#  - rewrite_rule:
#    - "^/?(.*) https://%{SERVER_NAME}/$1 [R,L]"
#
  $sslinstances                = {'site.drupalsites.nl-ssl' => {
                                  'serveraliases'   => '*.drupalsites.nl',
                                  'docroot'         => '/var/www/drupal',
                                  'directories'     => [{ 'path' => '/var/www/drupal', 'options' => '-Indexes +FollowSymLinks +MultiViews', 'allow_override' => 'All' }],
                                  'port'            => 443,
                                  'serveradmin'     => 'webmaster@naturalis.nl',
                                  'priority'        => 10,
                                  'ssl'             => 'true',
                                  'ssl_cert'        => '/etc/letsencrypt/live/site.drupalsite.nl/cert.pem',
                                  'ssl_key'         => '/etc/letsencrypt/live/site.drupalsite.nl/privkey.pem',
                                  'ssl_chain'       => '"/etc/letsencrypt/live/site.drupalsite.nl/chain.pem',
                                  'additional_includes' =>  '/opt/letsencrypt/certbot-apache/certbot_apache/options-ssl-apache.conf',
                                  },
                                },
){

  apt::key { 'ondrej':
    id      => '14AA40EC0831756756D7F66C4F4EA0AAE5267A6C',
    server  => 'pgp.mit.edu',
    notify  => Exec['apt_update']
  }

# install php and configure php.ini


  class { 'php::repo::ubuntu':
    version             => '7.0',
  }->
  class { '::php':
    ensure              => latest,
    composer            => false,
    require             => Apt::Key['ondrej'],
    extensions => {
      gd         => { 
        provider => 'apt',
        source   => 'php7-gd',
      },
      curl       => { 
        provider => 'apt',
        source   => 'php-curl',
      },
      mcrypt     => {
        provider => 'apt',
        source   => 'php-mcrypt',
      },
      mbstring   => {
        provider => 'apt',
        source   => 'php-mbstring',
      },
    },
    settings   => {
        'PHP/apc.rfc1867'         => '1',
        'PHP/max_execution_time'  => '90',
        'PHP/max_input_time'      => '300',
        'PHP/memory_limit'        => $role_drupal::php_memory_limit,
        'PHP/post_max_size'       => $role_drupal::post_max_size,
        'PHP/upload_max_filesize' => $role_drupal::upload_max_filesize,
        'Date/date.timezone'      => 'Europe/Amsterdam',
    },
  }

# custom pecl uploadprogress package, requires manage_repos => true in class php
  package {'php-uploadprogress':
    ensure          => latest,
    require         => Class['::php'],
    notify          => Service['apache2'],
  }

  class { 'apache':
    default_mods    => true,
    mpm_module      => 'prefork',
  }
  include apache::mod::php
  include apache::mod::rewrite

# enable ssl with or without letsencrypt based on config
  class { 'role_drupal::ssl': }

# Create instance, make sure ssl certs are installed first.
  class { 'role_drupal::instances':
    require     => Class['role_drupal::ssl'],
  }

# main drupal download and installation with custom profile
  if ($role_drupal::configuredrupal == true ) and ($role_drupal::install_profile_userepo == true ){
    class { 'role_drupal::repo':
    }
    exec { 'download drupal and untar drupal':
      command        => "/usr/bin/wget http://ftp.drupal.org/files/projects/drupal-${role_drupal::drupalversion}.tar.gz -O /opt/drupal-${role_drupal::drupalversion}.tar.gz && /bin/tar -xf /opt/drupal-${role_drupal::drupalversion}.tar.gz -C /opt",
      unless         => "/usr/bin/test -d ${role_drupal::docroot}/sites",
    }->
    exec { 'install drupal manual':
      command        => "/bin/mv /opt/drupal-${role_drupal::drupalversion}/* ${role_drupal::docroot}",
      unless         => "/usr/bin/test -d ${role_drupal::docroot}/sites",
      require        => File[$role_drupal::docroot],
    }->
    exec { 'install drupal manual profile':
      command        => "/bin/mv /opt/naturalisprofile/* ${role_drupal::docroot}/profiles",
      unless         => "/usr/bin/test -d ${role_drupal::docroot}/profiles/naturalis",
      require        => [File[$role_drupal::docroot],Vcsrepo['/opt/naturalisprofile']]
    }->
    class { 'role_drupal::install':
      require           => [Class['::php'],Exec['install drupal manual']],
    }
  }

# main drupal download and installation with default profile
  if ($role_drupal::configuredrupal == true ) and ($role_drupal::install_profile_userepo == false ){
    exec { 'download drupal and untar drupal no profile':
      command        => "/usr/bin/wget http://ftp.drupal.org/files/projects/drupal-${role_drupal::drupalversion}.tar.gz -O /opt/drupal-${role_drupal::drupalversion}.tar.gz && /bin/tar -xf /opt/drupal-${role_drupal::drupalversion}.tar.gz -C /opt",
      unless         => "/usr/bin/test -d ${role_drupal::docroot}/sites",
    }->
    exec { 'install drupal manual no profile':
      command        => "/bin/mv /opt/drupal-${role_drupal::drupalversion}/* ${role_drupal::docroot}",
      unless         => "/usr/bin/test -d ${role_drupal::docroot}/sites",
      require        => File[$role_drupal::docroot],
    }->
    class { 'role_drupal::install':
      require           => [Class['::php'],Exec['install drupal manual no profile']],
    }
  }


# mysql server 
  if $role_drupal::managedatabase {
    class { 'mysql::bindings':
      php_enable => true,
    }
    mysql::db { $role_drupal::dbname:
      ensure    => present,
      user      => $role_drupal::dbuser,
      password  => $role_drupal::dbpassword,
      host      => $role_drupal::dbhost,
      charset   => $role_drupal::dbcharset,
      collate   => $role_drupal::dbcollation,
      grant     => ['all'],
    }

   class { 'mysql::server::account_security':}

   if ($role_drupal::mysql_large_indexes == true ){
     class { 'mysql::server':
       root_password                => $role_drupal::mysql_root_password,
       override_options             => {
                'mysqld'            => {
                'innodb_large_prefix'     => $role_drupal::mysql_innodb_large_prefix,
                'innodb_file_format'      => $role_drupal::mysql_innodb_file_format,
                'innodb_file_per_table'   => $role_drupal::mysql_innodb_file_per_table,
                                       }
                }
    }
    } else {
      class { 'mysql::server':
        root_password           => $role_drupal::mysql_root_password,
      }
    }
  }

# custom folder settings, needed for boost module
  file { ["${role_drupal::docroot}/cache","${role_drupal::docroot}/cache/normal"]:
    ensure      => 'directory',
    mode        => '0755',
    owner       => 'www-data',
    require     => File[$role_drupal::docroot],
  }


# run cron job every hour
  if ($role_drupal::cron == true) {
    cron { 'drupal hourly cronjob':
      command => "/usr/bin/env PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin COLUMNS=72 /usr/local/bin/drush --root=${role_drupal::docroot} --quiet cron",
      user    => root,
      minute  => 0
    }
  }

# update when configured
  if ( $role_drupal::updatesecurity == true ) or ( $role_drupal::updateall == true ) {
      class { 'role_drupal::update':}
    }

# install tests scripts and export as sensu check
  file {'/usr/local/sbin/drupalchk.sh':
    ensure                  => 'file',
    mode                    => '0777',
    content                 => template('role_drupal/drupalchk.sh.erb')
  }

# export check so sensu monitoring can make use of it
  @@sensu::check { 'Check Drupal' :
    command     => '/usr/local/sbin/drupalchk.sh',
    interval    => $checks_defaults['interval'],
    occurrences => $checks_defaults['occurrrences'],
    refresh     => $checks_defaults['refresh'],
    handlers    => $checks_defaults['handlers'],
    subscribers => $checks_defaults['subscribers'],
    standalone  => $checks_defaults['standalone'],
    tag         => 'central_sensu',
}

}

