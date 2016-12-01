# == Class: role_drupal::updateold
#
# === Authors
#
# Author Name <hugo.vanduijn@naturalis.nl>
#
#
class role_drupal::updateold (
){

  if ( $role_drupal::updateall == true ) {
    exec { 'update_all_old_drush':
      command   => 'drush upc -u 1 --pipe | grep "Update-available" | cut -d" " -f1 | xargs drush up -u 1 -y',
      path      => '/sbin:/usr/bin:/usr/local/bin/:/bin/',
      provider  => shell,
      user      => 'root',
      onlyif    => 'drush upc -u 1 --pipe | grep -c "Update-available"'
    }
    exec { 'update_security_old_drush':
      command   => 'drush upc -u 1 --pipe | grep "SECURITY-UPDATE" | cut -d" " -f1 | xargs drush up -u 1 -y',
      path      => '/sbin:/usr/bin:/usr/local/bin/:/bin/',
      provider  => shell,
      user      => 'root',
      onlyif    => 'drush upc -u 1 --pipe | grep -c "SECURITY-UPDATE"'
    }
  } else {
    exec { 'update_security_old_drush':
      command   => 'drush upc -u 1 --pipe | grep "SECURITY-UPDATE" | cut -d" " -f1 | xargs drush up -u 1 -y',
      path      => '/sbin:/usr/bin:/usr/local/bin/:/bin/',
      provider  => shell,
      user      => 'root',
      onlyif    => 'drush upc -u 1 --pipe | grep -c "SECURITY-UPDATE"'
    }
  }

}
