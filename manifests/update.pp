# == Class: role_drupal::update
#
# === Authors
#
# Author Name <hugo.vanduijn@naturalis.nl>
#
#
class role_drupal::update (
  $updateall    = undef,
){

  if ( $updateall == true ) {
    exec { 'update_all':
      command   => 'drush pm-updatestatus --full | grep "Update available" | cut -d" " -f2 | xargs drush up -u 1 -y',
      path      => '/sbin:/usr/bin:/usr/local/bin/:/bin/',
      provider  => shell,
      user      => 'root',
      onlyif    => 'drush pm-updatestatus | grep -c "Update available"'
    }
    exec { 'update_security':
      command   => 'drush pm-updatestatus --full | grep "SECURITY" | cut -d" " -f2 | xargs drush up -u 1 -y',
      path      => '/sbin:/usr/bin:/usr/local/bin/:/bin/',
      provider  => shell,
      user      => 'root',
      onlyif    => 'drush pm-updatestatus | grep -c "SECURITY"'
    }
    exec { 'update_all_old_drush':
      command   => 'drush upc -u 1 --pipe | grep "Update-available" | cut -d" " -f1 | xargs drush up -u 1 -y',
      path      => '/sbin:/usr/bin:/usr/local/bin/:/bin/',
      provider  => shell,
      user      => 'root',
      onlyif    => 'drush upc -u 1 --pipe | grep -c "Update-available"'
    }
    exec { 'update_security_old_drush':
      command   => 'drush upc -u 1 --pipe | grep "Update-available" | cut -d" " -f1 | xargs drush up -u 1 -y',
      path      => '/sbin:/usr/bin:/usr/local/bin/:/bin/',
      provider  => shell,
      user      => 'root',
      onlyif    => 'drush upc -u 1 --pipe | grep -c "SECURITY-UPDATE"'
    }
  } else {
    exec { 'update_security':
      command   => 'drush pm-updatestatus --full | grep "SECURITY" | cut -d" " -f2 | xargs drush up -u 1 -y',
      path      => '/sbin:/usr/bin:/usr/local/bin/:/bin/',
      provider  => shell,
      user      => 'root',
      onlyif    => 'drush pm-updatestatus | grep -c "SECURITY"'
    }
    exec { 'update_security_old_drush':
      command   => 'drush upc -u 1 --pipe | grep "Update-available" | cut -d" " -f1 | xargs drush up -u 1 -y',
      path      => '/sbin:/usr/bin:/usr/local/bin/:/bin/',
      provider  => shell,
      user      => 'root',
      onlyif    => 'drush upc -u 1 --pipe | grep -c "SECURITY-UPDATE"'
    }
  }


# update composer and drush when new drush version is available
  if ( $updatedrush == true ) {
    exec { 'update drush':
      command     => 'composer global self-update & composer global update',
      path        => '/sbin:/usr/bin:/usr/local/bin/:/bin/',
      cwd         => '/root/.composer/vendor/drush/drush',
      environment => ['HOME=/root'],
      onlyif      => 'composer global show -o | grep -c "drush"'
    }
  }
}
