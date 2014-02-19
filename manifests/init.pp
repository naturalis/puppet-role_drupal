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
  $configuredrupal     = true,
  $dbpassword          = 'password',
  $docroot             = '/var/www/sisdrupal',
  $drupalversion       = '7.26',
  $drushversion        = '7.x-5.9',
  $extra_users_hash    = undef,
  $mysql_root_password = 'rootpassword',
  $instances           = {'site.drupalsites.nl' => {
                           'serveraliases'   => '*.drupalsites.nl',
                           'docroot'         => '/var/www/sisdrupal',
                           'directories'     => [{ 'path' => '/var/www/sisdrupal', 'options' => '-Indexes FollowSymLinks MultiViews', 'allow_override' => 'All' }],
                           'port'            => 80,
                           'serveradmin'     => 'webmaster@naturalis.nl',
                           'priority'        => 10,
                          },
                         },
){

# create extra users
  if $extra_users_hash {
    create_resources('base::users', parseyaml($extra_users_hash))
  }

# install php and configure php.ini
  php::module { [ 'gd','apc']: }
  php::module::ini { 'pecl-apc':
    settings => {
      'apc.rfc1867'      => '1',
      'apc.enabled'      => '1',
      'apc.shm_segments' => '1',
      'apc.shm_size'     => '64',
    }
  }

  class { 'apache':
    default_mods => true,
    mpm_module => 'prefork',
  }
  include apache::mod::php
  include apache::mod::rewrite


  if ($configuredrupal == true) {
    # Create instance, install php modules and download+untar drupal in specific order.
    class { 'role_drupal::instances': 
      instances => $instances,
    }->
    exec { 'download drupal and untar drupal':
      command => "/usr/bin/curl http://ftp.drupal.org/files/projects/drupal-${drupalversion}.tar.gz -o /tmp/drupal-${drupalversion}.tar.gz && /bin/tar -xf /tmp/drupal-${drupalversion}.tar.gz -C /tmp",
      unless  => "/usr/bin/test -d ${docroot}/sites",
    }->
    exec { 'install drupal manual':
      command => "/bin/mv /tmp/drupal-${drupalversion}/* ${docroot}",
      unless  => "/usr/bin/test -d ${docroot}/sites",
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
      require        => Exec['install drupal manual'],
    }->
    class { 'mysql::server::account_security':}
    class { 'mysql::server':
      root_password  => $mysql_root_password,
    }
  }
}
