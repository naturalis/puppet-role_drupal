class role_drupal::configure {

  if $role_drupal::installtype == 'package' {
    file { $role_drupal::docroot:
      ensure => link,
      target => $role_drupal::installroot,
    }
  }

  file { "${role_drupal::docroot}/.htaccess":
    ensure  => file,
    replace => "no",
    source  => 'puppet:///modules/role_drupal/htaccess',
  }

}
