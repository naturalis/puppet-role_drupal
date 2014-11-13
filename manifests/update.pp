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
      command   => 'drush upc -u 1 --pipe | grep "Update-available" | cut -d" " -f1 | xargs drush up -u 1 -y',
      path      => "/sbin:/usr/bin:/usr/local/bin/:/bin/",
      provider  => shell,
      user      => 'root',
      onlyif    => "drush upc -u 1 --pipe | grep -c 'Update-available'"
    }
  } else {
    exec { 'update_security':
      command   => 'drush upc -u 1 --pipe | grep "SECURITY-UPDATE" | cut -d" " -f1 | xargs drush up -u 1 -y',
      path      => "/sbin:/usr/bin:/usr/local/bin/:/bin/",
      provider  => shell,
      user      => 'root',
      onlyif    => "drush upc -u 1 --pipe | grep -c 'SECURITY-UPDATE'"
    }
  }
}
