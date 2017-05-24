# == Class: role_drupal::repo
#
# === Authors
#
# Author Name <hugo.vanduijn@naturalis.nl>
#
#
class role_drupal::repo (
){


# ensure git package for repo checkouts, conflicts with letsencrypt so only when letsencrypt is disabled.


#  if ( $role_drupal::enableletsencrypt == false ) {
    package { 'git':
      ensure => installed,
    }
#  }
  if ( $role_drupal::install_profile_reposshauth == false ) {
    vcsrepo { '/opt/naturalisprofile':
      ensure    => $role_drupal::install_profile_repoversion,
      provider  => $role_drupal::install_profile_repotype,
      source    => $role_drupal::install_profile_repo,
      require   => Package['git'],
      revision  => 'master',
    }
  } else {
    file { '/root/.ssh':
      ensure    => directory,
    }->
    file { "/root/.ssh/${role_drupal::install_profile_repokeyname}":
      ensure    => 'present',
      content   => $role_drupal::install_profile_repokey,
      mode      => '0600',
    }->
    file { '/root/.ssh/config':
      ensure    => 'present',
      content   =>  template('role_drupal/sshconfig.erb'),
      mode      => '0600',
    }->
    file{ '/usr/local/sbin/known_hosts.sh' :
      ensure    => 'present',
      mode      => '0700',
      source    => 'puppet:///modules/role_drupal/known_hosts.sh',
    }->
    exec{ 'add_known_hosts' :
      command   => '/usr/local/sbin/known_hosts.sh',
      path      => '/sbin:/usr/bin:/usr/local/bin/:/bin/',
      provider  => shell,
      user      => 'root',
      unless    => 'test -f /root/.ssh/known_hosts'
    }->
    file{ '/root/.ssh/known_hosts':
      mode      => '0600',
    }->
    vcsrepo { '/opt/naturalisprofile':
      ensure    => $role_drupal::install_profile_repoversion,
      provider  => $role_drupal::install_profile_repotype,
      source    => $role_drupal::install_profile_repo,
      user      => 'root',
      revision  => 'master',
      require   => Package['git'],
    }
  }
}

