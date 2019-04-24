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
      command   => 'docker-compose exec -T drupal drush up --no-backup -y',
      path      => '/sbin:/usr/bin:/usr/local/bin/:/bin/',
      cwd       => $role_drupal::repo_dir,
      provider  => shell,
      user      => 'root',
      onlyif    => 'docker-compose exec -T drupal drush pm-updatestatus | grep -c "Update available"'
    }
    exec { 'update_security':
      command   => 'docker-compose exec -T drupal drush up --no-backup -y',
      path      => '/sbin:/usr/bin:/usr/local/bin/:/bin/',
      provider  => shell,
      cwd       => $role_drupal::repo_dir,
      user      => 'root',
      onlyif    => 'docker-compose exec -T drupal drush pm-updatestatus | grep -c "SECURITY"'
    }
  } else {
    exec { 'update_security':
      command   => 'docker-compose exec -T drupal drush up --no-backup -y',
      path      => '/sbin:/usr/bin:/usr/local/bin/:/bin/',
      provider  => shell,
      cwd       => $role_drupal::repo_dir,
      user      => 'root',
      onlyif    => 'docker-compose exec -T drupal drush pm-updatestatus | grep -c "SECURITY"'
    }
  }
}
