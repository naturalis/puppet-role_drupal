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
  $modules             = ['token',
                          'ctools',
                          'rules',
                          'views',
                          'context',
                          'features',
                          'boxes',
                          'module_filter',
                          'pathauto',
                          'boost',
                          'google_analytics',
                          'i18n',
                          'panels',
                          'ckeditor',
                          'admin_menu',
                          'field_group',
                          'webform',
                          'libraries',
                          'smtp',
                          'menutree',
                          'contact',
                          'i18n_translation',
                          'references',
                          'page_manager',
                          'translation',
                          'i18n_string'],
  $cron                = true,
  $CKEditor            = true,
  $CKEditorURL         = 'http://download.cksource.com/CKEditor/CKEditor/CKEditor%204.3.2/ckeditor_4.3.2_standard.zip',
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
      'apc.shm_size'     => '64M',
    }
  }

  class { 'apache':
    default_mods => true,
    mpm_module => 'prefork',
  }
  include apache::mod::php
  include apache::mod::rewrite

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
    exec { 'install drupal manual':
      command        => "/bin/mv /tmp/drupal-${drupalversion}/* ${docroot}",
      unless         => "/usr/bin/test -d ${docroot}/sites",
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
      require        => Exec['install drupal manual'],
    }->
    drupal_module { $modules:
      ensure         => present,
    }->
    class { 'mysql::server::account_security':}
    class { 'mysql::server':
      root_password  => $mysql_root_password,
    }
# download and install CKEditor
    if ($CKEditor == true) {
      exec { 'download and unpack CKEditor':
        command      => "/usr/bin/curl ${CKEditorURL} -o /tmp/ckeditor.zip && /usr/bin/unzip /tmp/ckeditor.zip -d ${docroot}/sites/all/modules/ckeditor",
        unless       => "/usr/bin/test -f ${docroot}/sites/all/modules/ckeditor/ckeditor/ckeditor.js",
        require      => Drupal_module['ckeditor'],
      }
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
        command => "/usr/local/bin/drush @sites core-cron --yes",
        user    => root,
        minute  => 0
      }
    }

  }



}
