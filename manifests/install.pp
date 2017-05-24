class role_drupal::install ()
{
  include apache
  include apache::mod::php

  if ! member(['mysql', 'sqlite', 'pgsql', 'none'], $role_drupal::dbdriver) {
    fail("drupal: Database driver ${role_drupal::dbdriver} not supported! (mysql, pgsql, or sqlite)")
  }

  anchor { 'role_drupal::begin': }
  -> class { 'role_drupal::drush': }
  -> exec { 'install drupal':
        command => "/bin/tar -xf /tmp/drupal-${role_drupal::drupalversion}.tar.gz -C ${role_drupal::docroot} && rm /tmp/drupal-${role_drupal::drupalversion}.tar.gz",
        onlyif  => "/usr/bin/wget http://ftp.drupal.org/files/projects/drupal-${role_drupal::drupalversion}.tar.gz -O /tmp/drupal-${role_drupal::drupalversion}.tar.gz",
        creates => $role_drupal::docroot,
      }
  -> class { 'role_drupal::configure': }
  -> anchor { 'role_drupal::end': }

  class {'role_drupal::site': }

}
