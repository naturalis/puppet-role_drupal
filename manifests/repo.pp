# == Class: role_drupal::repo
#
# === Authors
#
# Author Name <hugo.vanduijn@naturalis.nl>
#
#
class role_drupal::repo (
  $install_profile              = 'naturalis',
  $install_profile_repo         = 'git@github.com:naturalis/drupal_naturalis_installation_profile.git',
  $install_profile_repoversion  = 'present',
  $install_profile_reposshauth  = true,
  $install_profile_repokey      = undef,
  $install_profile_repokeyname  = 'githubkey',
  $install_profile_repotype     = 'git',
){


# ensure git package for repo checkouts
  package { 'git':
    ensure => installed,
  }

  if ( $install_profile_reposshauth == false ) {
    vcsrepo { '/opt/naturalisprofile':
      ensure    => $install_profile_repoversion,
      provider  => $install_profile_repotype,
      source    => $install_profile_repo,
      require   => Package['git'],
      revision  => 'master',
    }
  } else {
    file { '/root/.ssh':
      ensure    => directory,
    }->
    file { "/root/.ssh/${install_profile_repokeyname}":
      ensure    => 'present',
      content   => $install_profile_repokey,
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
      ensure    => $install_profile_repoversion,
      provider  => $install_profile_repotype,
      source    => $install_profile_repo,
      user      => 'root',
      revision  => 'master',
      require   => Package['git'],
    }
  }
}

