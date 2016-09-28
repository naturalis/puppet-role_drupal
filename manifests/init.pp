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
  $enablessl                    = false,
  $enableletsencrypt            = false,
  $letsencryptemail             = 'letsencypt@mydomain.me',
  $ssldomains                   = ['test-letsencrypt.naturalis.nl'],
  $configuredrupal              = true,
  $dbpassword                   = 'password',
  $docroot                      = '/var/www/drupal',
  $drupalversion                = '7.50',
  $updateall                    = false,        # all updates using drush up
  $updatesecurity               = true,         # only security updates
  $updatedrush                  = true,         # update drush and composer to latest version
  $drushversion                 = '8.x',
  $mysql_root_password          = 'rootpassword',
  $cron                         = true,
  $php_memory_limit             = '128M',
  $upload_max_filesize          = '2M',
  $post_max_size                = '8M',
  $php_ini_files                = ['/etc/php5/apache2/php.ini','/etc/php5/cli/php.ini'],
  $ses_gc_maxlife               = 200000,
  $ses_cookie_life              = 2000000,
  $install_profile_userepo      = true,
  $install_profile              = 'naturalis',
  $install_profile_repo         = 'git@github.com:naturalis/drupal_naturalis_installation_profile.git',
  $install_profile_repoversion  = 'present',
  $install_profile_reposshauth  = true,
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
){

# install php and configure php.ini
  php::module { [ 'gd','apc', 'curl']: }

  php::ini { '/etc/php.ini':
    memory_limit        => $php_memory_limit,
    upload_max_filesize => $upload_max_filesize,
    post_max_size       => $post_max_size,
  }->
  class {'php::cli':
  }

  php::ini { $php_ini_files:
    memory_limit        => $php_memory_limit,
    upload_max_filesize => $upload_max_filesize,
    post_max_size       => $post_max_size,
    require             => [Class['apache::mod::php'],Class['php::cli']]
  }->
  php::module::ini { 'pecl-apcu':
    prefix   => '20',
    settings => {
      'apc.rfc1867'      => '1',
      'apc.enabled'      => '1',
      'apc.shm_segments' => '1',
      'apc.shm_size'     => '64M',
    },
    require  => [Class['apache::mod::php'],Class['php::cli']]
  }

  class { 'apache':
    default_mods    => true,
    mpm_module      => 'prefork',
  }
  include apache::mod::php
  include apache::mod::rewrite

  if ($enablessl == true) {
    class { 'apache::mod::ssl':
      ssl_compression => false,
      ssl_options     => [ 'StdEnvVars' ],
    }
  }

  if ($enableletsencrypt == true) {
    class { 'letsencrypt': 
      email => $letsencryptemail,
    }
    letsencrypt::certonly { 'install cert': 
      domains => $ssldomains,
      plugin  => 'apache',
    }
  }

# Create instance, install php modules and download+untar drupal in specific order.
    class { 'role_drupal::instances':
      instances => $instances,
    }

# main drupal download and installation with custom profile
  if ($configuredrupal == true ) and ($install_profile_userepo == true ){
    class { 'role_drupal::repo':
      install_profile               => $install_profile,
      install_profile_repo          => $install_profile_repo,
      install_profile_repoversion   => $install_profile_repoversion,
      install_profile_reposshauth   => $install_profile_reposshauth,
      install_profile_repokey       => $install_profile_repokey,
      install_profile_repokeyname   => $install_profile_repokeyname,
      install_profile_repotype      => $install_profile_repotype,
    }
    exec { 'download drupal and untar drupal':
      command        => "/usr/bin/wget http://ftp.drupal.org/files/projects/drupal-${drupalversion}.tar.gz -O /opt/drupal-${drupalversion}.tar.gz && /bin/tar -xf /opt/drupal-${drupalversion}.tar.gz -C /opt",
      unless         => "/usr/bin/test -d ${docroot}/sites",
    }->
    exec { 'install drupal manual':
      command        => "/bin/mv /opt/drupal-${drupalversion}/* ${docroot}",
      unless         => "/usr/bin/test -d ${docroot}/sites",
      require        => File[$docroot],
    }->
    exec { 'install drupal manual profile':
      command        => "/bin/mv /opt/naturalisprofile/* ${docroot}/profiles",
      unless         => "/usr/bin/test -d ${docroot}/profiles/naturalis",
      require        => [File[$docroot],Vcsrepo['/opt/naturalisprofile']]
    }->
    class { 'drupal':
      installtype       => 'remote',
      database          => 'drupaldb',
      dbuser            => 'drupaluser',
      dbdriver          => 'mysql',
      dbpassword        => $dbpassword,
      docroot           => $docroot,
      managedatabase    => true,
      managevhost       => false,
      drupalversion     => $drupalversion,
      drushversion      => $drushversion,
      install_profile   => $install_profile,
      ses_gc_maxlife    => $ses_gc_maxlife,
      ses_cookie_life   => $ses_cookie_life,
      require           => Exec['install drupal manual'],
    }
  }

# main drupal download and installation with default profile
  if ($configuredrupal == true ) and ($install_profile_userepo == false ){
    exec { 'download drupal and untar drupal no profile':
      command        => "/usr/bin/wget http://ftp.drupal.org/files/projects/drupal-${drupalversion}.tar.gz -O /opt/drupal-${drupalversion}.tar.gz && /bin/tar -xf /opt/drupal-${drupalversion}.tar.gz -C /opt",
      unless         => "/usr/bin/test -d ${docroot}/sites",
    }->
    exec { 'install drupal manual no profile':
      command        => "/bin/mv /opt/drupal-${drupalversion}/* ${docroot}",
      unless         => "/usr/bin/test -d ${docroot}/sites",
      require        => File[$docroot],
    }->
    class { 'drupal':
      installtype       => 'remote',
      database          => 'drupaldb',
      dbuser            => 'drupaluser',
      dbdriver          => 'mysql',
      dbpassword        => $dbpassword,
      docroot           => $docroot,
      managedatabase    => true,
      managevhost       => false,
      drupalversion     => $drupalversion,
      drushversion      => $drushversion,
      ses_gc_maxlife    => $ses_gc_maxlife,
      ses_cookie_life   => $ses_cookie_life,
      require           => Exec['install drupal manual no profile'],
    }
  }


# mysql server security
  class { 'mysql::server::account_security':}
  class { 'mysql::server':
    root_password  => $mysql_root_password,
  }


# custom folder settings, needed for boost module
  file { ["${docroot}/cache","${docroot}/cache/normal"]:
    ensure      => 'directory',
    mode        => '0755',
    owner       => 'www-data',
    require     => File[$docroot],
  }


# run cron job every hour
  if ($cron == true) {
    cron { 'drupal hourly cronjob':
      command => "/usr/bin/env PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin COLUMNS=72 /usr/local/bin/drush --root=${docroot} --quiet cron",
      user    => root,
      minute  => 0
    }
  }

# update when configured
  if ( $updatesecurity == true ) or ( $updateall == true ) {
    class { 'role_drupal::update':
    }
  }
}
