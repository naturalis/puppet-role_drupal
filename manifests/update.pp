# == Class: role_drupal::update
#
# === Authors
#
# Author Name <hugo.vanduijn@naturalis.nl>
#
#
class role_drupal::update (
){

  if ( $role_drupal::updateall == true ) {
    exec { 'update_all':
      command   => '"drush pm-updatestatus --full" | grep "Update available" | cut -d" " -f2 | xargs drush up --no-backup -u 1 -y',
      path      => '/sbin:/usr/bin:/usr/local/bin/:/bin/',
      cwd       => '/opt',
      provider  => shell,
      user      => 'root',
      onlyif    => 'drush pm-updatestatus | grep -c "Update available"'
    }
    exec { 'update_security':
      command   => '"drush pm-updatestatus --full" | grep "SECURITY" | cut -d" " -f2 | xargs drush up --no-backup -u 1 -y',
      path      => '/sbin:/usr/bin:/usr/local/bin/:/bin/',
#      provider  => shell,
      user      => 'root',
      onlyif    => 'drush pm-updatestatus | grep -c "SECURITY"'
    }
  } else {
    exec { 'update_security':
      command   => '"drush pm-updatestatus --full" | grep "SECURITY" | cut -d" " -f2 | xargs drush up --no-backup -u 1 -y',
      path      => '/sbin:/usr/bin:/usr/local/bin/:/bin/',
      provider  => shell,
      user      => 'root',
      onlyif    => 'drush pm-updatestatus --security-only | grep -c SECURITY'
    }
  }


# update composer and drush when new drush version is available
  if ( $role_drupal::updatedrush == true ) {
    exec { 'update drush':
      command     => 'composer global self-update & composer global update',
      path        => '/sbin:/usr/bin:/usr/local/bin/:/bin/',
      cwd         => '/root/.composer/vendor/drush/drush',
      environment => ['HOME=/root'],
      onlyif      => 'composer global show -o | grep -c "drush"'
    }
  }
}
