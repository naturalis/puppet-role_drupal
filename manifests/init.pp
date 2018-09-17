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
  $drupal_version               = '7.59',
  $drupal_md5                   = '7e09c6b177345a81439fe0aa9a2d15fc',
  $drush_version                = '8.1',
  $base_url                     = '',
  $protocol                     = 'http',
  $base_domain                  = '',
  $install_profile              = 'naturalis',
  $web_external_port            = '80',
  $dev                          = '0',
  $manageenv                    = 'no',
  $caserver                     = 'https://acme-staging-v02.api.letsencrypt.org/directory',  # Default: "https://acme-v02.api.letsencrypt.org/directory"
  $drupal_site_url              = 'test-drupal.naturalis.nl',
  $drupal_sans_url              = ['test1-drupal.naturalis.nl','test2-drupal.naturalis.nl'],
  $logrotate_hash               = { 'apache2'    => { 'log_path' => '/data/drupal/apachelog',
                                                      'post_rotate' => "(cd ${repo_dir}; docker-compose exec drupal service apache2 reload)",
                                                      'extraline' => 'su root docker'},
                                    'mysql'      => { 'log_path' => '/data/drupal/mysqllog',
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
    path => '/usr/local/bin/',
    cwd  => $role_drupal::repo_dir,
  }

  file { ['/data','/data/config','/data/drupal','/data/drupal/initdb','/data/drupal/mysqlconf','/data/drupal/apachelog','/data/drupal/mysqllog','/opt/traefik'] :
    ensure              => directory,
    owner               => 'root',
    group               => 'docker',
    mode                => '0770',
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

  file { '/data/drupal/mysqlconf/my-drupal.cnf':
    ensure   => file,
    mode     => '0644',
    replace  => $role_drupal::manageenv,
    content  => template('role_drupal/my-drupal.cnf.erb'),
    require  => File['/data/drupal/mysqlconf'],
  }

  file { '/data/drupal/mysqlconf/my-drupal-client.cnf':
    ensure   => file,
    mode     => '0600',
    replace  => $role_drupal::manageenv,
    content  => template('role_drupal/my-drupal-client.cnf.erb'),
    require  => File['/data/drupal/mysqlconf'],
  }

 file { "${role_drupal::repo_dir}/traefik.toml" :
    ensure   => file,
    content  => template('role_drupal/traefik.toml.erb'),
    require  => Vcsrepo[$role_drupal::repo_dir],
    notify   => Exec['Restart containers on change'],
  }

  file { "${role_drupal::repo_dir}/.env":
    ensure   => file,
    mode     => '0600',
    replace  => $role_drupal::manageenv,
    content  => template('role_drupal/env.erb'),
    require  => Vcsrepo[$role_drupal::repo_dir],
    notify   => Exec['Restart containers on change'],
  }

  file { "${role_drupal::repo_dir}/acme.json":
    ensure   => file,
    mode     => '0600',
    require  => Vcsrepo[$role_drupal::repo_dir],
  }


  class {'docker::compose': 
    ensure      => present,
    version     => $role_drupal::compose_version,
    notify      => Exec['apt_update']
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
    revision  => 'master',
    require   => [Package['git'],File[$role_drupal::repo_dir]]
  }

  docker_compose { "${role_drupal::repo_dir}/docker-compose.yml":
    ensure      => present,
    require     => [
      Vcsrepo[$role_drupal::repo_dir],
      Docker_network['web'],
      File["${role_drupal::repo_dir}/acme.json"],
      File["${role_drupal::repo_dir}/.env"]
    ]
  }

  exec { 'Pull containers' :
    command  => 'docker-compose pull',
    schedule => 'everyday',
  }

  exec { 'Up the containers to resolve updates' :
    command  => 'docker-compose up -d',
    schedule => 'everyday',
    require  => [
      Exec['Pull containers'],
      Docker_compose["${role_drupal::repo_dir}/docker-compose.yml"]
    ]
  }

  exec {'Restart containers on change':
    refreshonly => true,
    command     => 'docker-compose up -d',
    require     => Docker_compose["${role_drupal::repo_dir}/docker-compose.yml"]
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
3