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
  $configuredrupal              = true,
  $dbpassword                   = 'password',
  $docroot                      = '/var/www/sisdrupal',
  $drupalversion                = '7.30',
  $drupalupdate                 = undef,
  $drushversion                 = '7.x-5.9',
  $extra_users_hash             = undef,
  $mysql_root_password          = 'rootpassword',
  $cron                         = true,
  $install_profile              = 'naturalis',
  $install_profile_repo         = 'svn://dev2.etibioinformatics.nl/drupal_naturalis_installation_profile',
  $install_profile_repoversion  = 'present',
  $install_profile_repotype     = 'svn',
  $instances                    = {'site.drupalsites.nl' => {
                                 'serveraliases'   => '*.drupalsites.nl',
                                 'docroot'         => '/var/www/sisdrupal',
                                 'directories'     => [{ 'path' => '/var/www/sisdrupal', 'options' => '-Indexes FollowSymLinks MultiViews', 'allow_override' => 'All' }],
                                 'port'            => 80,
                                 'serveradmin'     => 'webmaster@naturalis.nl',
                                 'priority'        => 10,
                                },
                               },
  # variables needed for foreman compatibility with produktion environment
  $modules             = undef,
  $CKEditor            = undef,
  $CKEditorURL         = undef,

){

# create extra users
  if $extra_users_hash {
    create_resources('base::users', parseyaml($extra_users_hash))
  }

# install subversion
  package { 'subversion':
    ensure => installed,
  }

# install php and configure php.ini
  php::module { [ 'gd','apc', 'curl']: }
  php::ini { '/etc/php.ini':
  } ->
  class { 'php::cli':
  }
  php::module::ini { 'pecl-apc':
    settings => {
      'apc.rfc1867'      => '1',
      'apc.enabled'      => '1',
      'apc.shm_segments' => '1',
      'apc.shm_size'     => '64M',
    }
  }

  class { 'apache':
    default_mods => true,
    mpm_module => 'prefork',
  }
  include apache::mod::php
  include apache::mod::rewrite

  if ($enablessl == true) {
    class { 'apache::mod::ssl':
      ssl_compression => false,
      ssl_options     => [ 'StdEnvVars' ],
    }
  }

# Create instance, install php modules and download+untar drupal in specific order.
    class { 'role_drupal::instances': 
      instances => $instances,
    }

# main drupal download and installation
  if ($configuredrupal == true) {
    exec { 'download drupal and untar drupal':
      command        => "/usr/bin/curl http://ftp.drupal.org/files/projects/drupal-${drupalversion}.tar.gz -o /tmp/drupal-${drupalversion}.tar.gz && /bin/tar -xf /tmp/drupal-${drupalversion}.tar.gz -C /tmp",
      unless         => "/usr/bin/test -d ${docroot}/sites",
    }->
    vcsrepo { "/tmp/naturalisprofile":
      ensure   => $install_profile_repoversion,
      provider => $install_profile_repotype,
      source   => $install_profile_repo,
      require  => Package['subversion'],
    }->
    exec { 'install drupal manual':
      command        => "/bin/mv /tmp/drupal-${drupalversion}/* ${docroot}",
      unless         => "/usr/bin/test -d ${docroot}/sites",
      require        => File[$docroot],
    }->
    exec { 'install drupal manual profile':
      command        => "/bin/mv /tmp/naturalisprofile/trunk/* ${docroot}/profiles",
      unless         => "/usr/bin/test -d ${docroot}/profiles/naturalis",
      require        => File[$docroot],
    }->
    class { 'drupal':
      installtype    => 'remote',
      database       => 'drupaldb',
      dbuser         => 'drupaluser',
      dbdriver       => 'mysql',
      dbpassword     => $dbpassword,
      docroot        => $docroot,
      managedatabase => true,
      managevhost    => false,
      drupalversion  => $drupalversion,
      drushversion   => $drushversion,
      update         => $drupalupdate,
      install_profile => $install_profile,
      require        => Exec['install drupal manual'],
    } 
    class { 'mysql::server::account_security':} 
    class { 'mysql::server':
      root_password  => $mysql_root_password,
    } 
#    }

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
        command => "/usr/local/bin/drush @sites core-cron --yes",
        user    => root,
        minute  => 0
      }
    }

  }



}
