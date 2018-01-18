class role_drupal::drush (
) {
  # install composer
  exec { 'install composer':
      command     => '/usr/bin/curl -sS https://getcomposer.org/installer | /usr/bin/php -- --install-dir=/usr/local/bin --filename=composer',
      environment => ['HOME=/root'],
      unless      => '/usr/bin/test -f /usr/local/bin/composer',
  }

  exec { 'install drush':
      command     => "/usr/local/bin/composer global require drush/drush:${role_drupal::drushversion}",
      environment => ['HOME=/root'],
      unless      => '/usr/bin/test -f /root/.composer/vendor/drush/drush/drush',
      require     => Exec['install composer']
  }

  file { '/usr/local/bin/drush':
    ensure  => symlink,
    target  => '/root/.composer/vendor/drush/drush/drush',
    require => Exec['install drush'],
  }

  file { '/etc/drush':
    ensure => directory,
  }

  file { '/etc/drush/drushrc.php':
    ensure  => file,
    content => template('role_drupal/drushrc.php.erb'),
  }

  # Add entries to sudoers. sensu user can run drush commands services..
  augeas { "sudodrush":
    context => "/files/etc/sudoers",
    changes => [
      "set Cmnd_Alias[alias/name = 'SERVICES']/alias/name SERVICES",
      "set Cmnd_Alias[alias/name = 'SERVICES']/alias/command[1] '/usr/local/bin/drush'",
      "set spec[user = 'sensu']/user sensu",
      "set spec[user = 'sensu']/host_group/host ALL",
      "set spec[user = 'sensu']/host_group/command SERVICES",
      "set spec[user = 'sensu']/host_group/command/runas_user root",
      "set spec[user = 'sensu']/host_group/command/tag NOPASSWD",
      ],
  }

}

