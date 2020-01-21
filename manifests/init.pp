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
  $compose_version              = '1.17.1',
  $repo_source                  = 'https://github.com/naturalis/docker-drupal.git',
  $repo_ensure                  = 'present',
  $repo_dir                     = '/opt/docker-drupal',
  $mysql_db                     = 'drupal',
  $mysql_host                   = 'db',
  $mysql_user                   = 'drupal_user',
  $mysql_password               = 'PASSWORD',
  $mysql_root_password          = 'ROOTPASSWORD',
  $git_branch                   = 'master',
  $composer_allow_superuser     = '1',
  $table_prefix                 = '',
  $base_path                    = '/data',
  $drupal_version               = '7.60',
  $drupal_md5                   = 'ba14bf3ddc8e182adb49eb50ae117f3e',
  $drush_version                = '8.1',
  $base_url                     = '',
  $protocol                     = 'http',
  $base_domain                  = '',
  $install_profile              = 'naturalis',
  $web_external_port            = '8080',
  $dev                          = '0',
  $manageenv                    = 'no',
  $enable_ssl                   = true,
  $letsencrypt_certs            = true,
  $traefik_whitelist            = false,
  $traefik_whitelist_array      = ['172.16.0.0/12'],
# cert hash = location to cert
  $traefik_cert_hash            = { '/etc/letsencrypt/live/site1.site.org/fullchain.pem' =>  '/etc/letsencrypt/live/site1.site.org/privkey.pem',
                                    '/etc/letsencrypt/live/site2.site.org/fullchain.pem' =>  '/etc/letsencrypt/live/site2.site.org/privkey.pem',
                                  },
  $drupal_site_url_array        = ['test-drupal.naturalis.nl','www.test-drupal.naturalis.nl'],  # first site will be used for traefik certificate
  $logrotate_hash               = { 'apache2'    => { 'log_path' => '/data/www/log/apache2',
                                                      'post_rotate' => "(cd ${repo_dir}; docker-compose exec drupal service apache2 reload)",
                                                      'extraline' => 'su root docker'},
                                    'mysql'      => { 'log_path' => '/data/database/mysqllog',
                                                      'post_rotate' => "(cd ${repo_dir}; docker-compose exec db mysqladmin flush-logs)",
                                                      'extraline' => 'su root docker'},
                                    'drupal'   => { 'log_path' => '/data/drupal/www/log',
                                                      'rotate' => '183',
                                                      'extraline' => 'su root www-data'},
                                 },
# drupal settings
  $updateall                    = false,                                   # all updates using drush up
  $updatesecurity               = true,                                    # only security updates
  $updatedrush                  = true,                                    # update drush and composer to latest version
  $testscriptsdir               = '/opt/repo/scripts',

# sensu check settings
  $checks_defaults    = {
    interval      => 600,
    occurrences   => 3,
    refresh       => 60,
    handlers      => ['drupal_mailer','default'],
    subscribers   => ['appserver'],
    standalone    => true },

){

  include 'docker'
  include 'stdlib'

  Exec {
    path => ['/usr/local/bin/','/usr/bin','/bin'],
    cwd  => $role_drupal::repo_dir,
  }

  file { ['/data','/data/config','/data/drupal','/data/database','/data/database/mysqlconf'] :
    ensure              => directory,
    owner               => 'root',
    group               => 'wheel',
    mode                => '0775',
    require             => Class['docker'],
  }

  file { $role_drupal::repo_dir:
    ensure              => directory,
    mode                => '0770',
  }

  file { '/data/config/settings.php':
    ensure   => file,
    mode     => '0644',
    content  => template('role_drupal/settings.erb'),
    require  => File['/data/config'],
  }

  file { '/data/database/mysqlconf/my-drupal.cnf':
    ensure   => file,
    mode     => '0644',
    replace  => $role_drupal::manageenv,
    content  => template('role_drupal/my-drupal.cnf.erb'),
    require  => File['/data/database/mysqlconf'],
  }

  file { '/data/database/mysqlconf/my-drupal-client.cnf':
    ensure   => file,
    mode     => '0600',
    replace  => $role_drupal::manageenv,
    content  => template('role_drupal/my-drupal-client.cnf.erb'),
    require  => File['/data/database/mysqlconf'],
  }

 file { "${role_drupal::repo_dir}/traefik.toml" :
    ensure   => file,
    content  => template('role_drupal/traefik.toml.erb'),
    require  => Vcsrepo[$role_drupal::repo_dir],
    notify   => Exec['Restart traefik on change'],
  }

  file { "${role_drupal::repo_dir}/.env":
    ensure   => file,
    mode     => '0600',
    replace  => $role_drupal::manageenv,
    content  => template('role_drupal/env.erb'),
    require  => Vcsrepo[$role_drupal::repo_dir],
    notify   => Exec['Restart containers on change'],
  }

  class {'docker::compose': 
    ensure      => present,
    version     => $role_drupal::compose_version,
    notify      => Exec['apt_update'],
    require     => File["${role_drupal::repo_dir}/.env"]
  }

  docker_network { 'web':
    ensure   => present,
  }

  ensure_packages(['git','python3'], { ensure => 'present' })

  vcsrepo { $role_drupal::repo_dir:
    ensure    => $role_drupal::repo_ensure,
    source    => $role_drupal::repo_source,
    provider  => 'git',
    user      => 'root',
    revision  => '0.0.1',
    require   => [Package['git'],File[$role_drupal::repo_dir]]
  }

#  docker_compose { "${role_drupal::repo_dir}/docker-compose.yml":
#    ensure      => present,
#    options     => "-p ${role_drupal::repo_dir} ",
#    require     => [
#      Vcsrepo[$role_drupal::repo_dir],
#      Docker_network['web'],
#      File["${role_drupal::repo_dir}/.env"]
#    ]
#  }

  exec { 'Pull containers' :
    command  => 'docker-compose pull',
    schedule => 'everyday',
  }

  exec { 'Docker system prune' :
    command  => 'docker system prune -af',
    schedule => 'everyday',
  }

  exec { 'Up the containers to resolve updates' :
    command  => 'docker-compose up -d',
    schedule => 'everyday',
    require  => [
      Exec['Pull containers'],
      Vcsrepo[$role_drupal::repo_dir],
      Docker_network['web'],
      File["${role_drupal::repo_dir}/.env"]
    ]
  }

  exec {'Restart containers on change':
    refreshonly => true,
    command     => 'docker-compose up -d',
    require     => [
      Vcsrepo[$role_drupal::repo_dir],
      Docker_network['web'],
      File["${role_drupal::repo_dir}/.env"]
    ]
  }

  exec {'Restart traefik on change':
    refreshonly => true,
    command     => 'docker-compose restart traefik',
    require     => [
      Vcsrepo[$role_drupal::repo_dir],
      Docker_network['web'],
      File["${role_drupal::repo_dir}/.env"]
    ]
  }

  exec {'Start containers if none are running':
    command     => 'docker-compose up -d',
    onlyif      => 'docker-compose ps | wc -l | grep -c 2',
    require     => [
      Vcsrepo[$role_drupal::repo_dir],
      Docker_network['web'],
      File["${role_drupal::repo_dir}/.env"]
    ]
  }
  
  # deze gaat per dag 1 keer checken
  # je kan ook een range aan geven, bv tussen 7 en 9 's ochtends
  schedule { 'everyday':
     period  => daily,
     repeat  => 1,
     range => '5-7',
  }

  create_resources('role_drupal::logrotate', $logrotate_hash)


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

# add sudoers rule for running drupalchk
  file_line {"Add password less sudo entry for check":
    path   => '/etc/sudoers',
    line   => 'sensu ALL = (root) NOPASSWD : /usr/local/sbin/drupalchk.sh'
  }

# export check so sensu monitoring can make use of it
  @@sensu::check { 'Check Drupal' :
    command     => 'sudo /usr/local/sbin/drupalchk.sh',
    interval    => $checks_defaults['interval'],
    occurrences => $checks_defaults['occurrrences'],
    refresh     => $checks_defaults['refresh'],
    handlers    => $checks_defaults['handlers'],
    subscribers => $checks_defaults['subscribers'],
    standalone  => $checks_defaults['standalone'],
    tag         => 'central_sensu',
  }

}
