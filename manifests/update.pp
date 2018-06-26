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
      command   => 'docker-compose exec drupal drush "pm-updatestatus --full" | grep "Update available" | cut -d" " -f2 | xargs drush up --no-backup -u 1 -y',
      path      => '/sbin:/usr/bin:/usr/local/bin/:/bin/',
      cwd       => $role_drupal::repo_dir,
      provider  => shell,
      user      => 'root',
      onlyif    => 'docker-compose exec drupal drush pm-updatestatus | grep -c "Update available"'
    }
    exec { 'update_security':
      command   => 'docker-compose exec drupal drush "pm-updatestatus --full" | grep "SECURITY" | cut -d" " -f2 | xargs docker-compose exec drupal drush up --no-backup -u 1 -y',
      path      => '/sbin:/usr/bin:/usr/local/bin/:/bin/',
#      provider  => shell,
      cwd       => $role_drupal::repo_dir,
      user      => 'root',
      onlyif    => 'docker-compose exec drupal drush pm-updatestatus | grep -c "SECURITY"'
    }
  } else {
    exec { 'update_security':
      command   => 'docker-compose exec drupal drush "pm-updatestatus --full" | grep "SECURITY" | cut -d" " -f2 | xargs docker-compose exec drupal drush up --no-backup -u 1 -y',
      path      => '/sbin:/usr/bin:/usr/local/bin/:/bin/',
      cwd       => $role_drupal::repo_dir,
      provider  => shell,
      user      => 'root',
      onlyif    => 'docker-compose exec drupal drush pm-updatestatus | grep -c "SECURITY"'
    }
  }


# update composer and drush when new drush version is available
#  if ( $role_drupal::updatedrush == true ) {
#    exec { 'update drush':
#      command     => 'docker-compose exec drupal composer global self-update & composer global update',
#      path        => '/sbin:/usr/bin:/usr/local/bin/:/bin/',
#      cwd       => $role_drupal::repo_dir,
#      cwd         => '/root/.composer/vendor/drush/drush',
#      environment => ['HOME=/root'],
#      onlyif      => 'docker-compose exec drupal composer global show -o | grep -c "drush"'
#    }
#  }
}
