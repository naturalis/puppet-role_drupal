class role_drupal::site (
  $ensure         = 'present',
  $sitename       = 'default',
) {
  require role_drupal::configure

  # TODO: more validation
  if ! member(['absent', 'present'], $ensure) {
    fail("role_drupal::site Ensure value ${ensure} not supported! (absent or present)")
  }
  if ! member(['mysql', 'sqlite', 'pgsql'], $role_drupal::dbdriver) {
    fail("role_drupal::site Database driver ${role_drupal::dbdriver} not supported! (mysql, pgsql, or sqlite)")
  }
  $root  = "${role_drupal::docroot}/sites/${sitename}"

  # the name default is handled specially
  if $sitename == 'default' {
    $vhost = $::fqdn
  }
  else {
    $vhost = $sitename
  }

  if $ensure == 'absent' {
    file { $root:
      ensure => absent,
      force  => true,
    }
  }
  else {
    File {
      owner => 'root',
      group => 'root',
      mode  => '0644',
    }

    file { $root:
      ensure => directory,
    }

    file { ["${root}/modules", "${root}/themes"]:
      ensure => directory,
      owner  => 'www-data',
      }
    }

    file { "${root}/files":
      ensure => directory,
      owner  => 'www-data',
    }

    file { "${root}/settings.php":
      ensure  => file,
      mode    => '0444',
      content => template('role_drupal/settings.php.erb'),
    } ->

    exec { "install ${sitename} drupal site":
      command   => "drush site-install ${role_drupal::install_profile} --account-pass='${role_drupal::admin_password}' -l ${sitename} --yes --site-name=${sitename}",
      path      => '/usr/local/bin:/bin:/usr/bin',
      unless    => "drush core-status -l ${sitename} | grep 'bootstrap.*Successful'",
      logoutput => true,
      require   => Class['role_drupal::drush'],
    }
}
