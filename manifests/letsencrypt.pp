# == Define: role_drupal::letsencrypt
#
# === Authors
#
# Author Name <foppe.pieters@naturalis.nl>
#
#
class role_drupal::letsencrypt (
  $path          = $role_drupal::letsencrypt_path,
  $repo          = $role_drupal::letsencrypt_repo,
  $version       = $role_drupal::letsencrypt_version,
  $live          = $role_drupal::letsencrypt_live,
){
  # install letsencrypt repo
  vcsrepo { $path:
    ensure      => latest,
    provider    => git,
    source      => $repo,
    revision    => $version,
    notify      => Exec['initialize letsencrypt'],
  }
  #installing letsencrypt
  exec { 'initialize letsencrypt':
    command     => "${path}/letsencrypt-auto --agree-tos -h",
    refreshonly => true,
  }
  # install ini file
  file { "${path}/cli.ini":
    ensure      => file,
    mode        => '0644',
    owner       => 'root',
    group       => 'root',
    content     => template('role_drupal/cli.ini.erb'),
    require     => Exec['initialize letsencrypt'],
  }
  # install apache ssl config
  file { "/etc/letsencrypt/options-ssl-apache.conf":
    ensure      => file,
    mode        => '0644',
    owner       => 'root',
    group       => 'root',
    content     => template('role_drupal/options-ssl-apache.conf.erb'),
    require     => [Exec['initialize letsencrypt'],Exec['install letsencrypt']],
  }
  # installing cert and authenticate on port 443, before apache binds the port
  exec { 'install letsencrypt':
    command     => "${path}/letsencrypt-auto certonly --config ${path}/cli.ini",
    creates     => $live,
    path        => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
    require     => File["${path}/cli.ini"]
  }

  # renew cert each week
  file { '/usr/local/sbin/renew_cert':
    ensure        => file,
    mode          => '0755',
    owner         => 'root',
    group         => 'root',
    content       => template('role_drupal/renew_cert.erb'),
  }

  cron { 'renew cert on sunday':
    command       => '/usr/local/sbin/renew_cert',
    user          => 'root',
    require       => File['/usr/local/sbin/renew_cert'],
    weekday       => 7,
  }

 # create ssl check script for usage with monitoring tools ( sensu )
  file {'/usr/local/sbin/sslchk.sh':
    ensure        => 'file',
    mode          => '0777',
    content       => template('role_drupal/sslchk.sh.erb')
  }

 # export check so sensu monitoring can make use of it
  @sensu::check { 'Check SSL expire date' :
    command => '/usr/local/sbin/sslchk.sh',
    tag     => 'central_sensu',
  }

}
