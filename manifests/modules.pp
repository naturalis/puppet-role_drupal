# Install drupal modules using drush

define role_drupal::modules (
    $module        = $name,
)
{
  exec { "Install ${module}":
    command        => "/usr/local/bin/drush dl ${module} && /usr/local/bin/drush en -y ${module}",
    unless         => ["/usr/bin/test -d ${role_drupal::docroot}/sites/all/modules/${module}",
                       "/usr/bin/test -d ${role_drupal::docroot}/modules/${module}"],
    require        => [Class['php::cli'],Exec['install default drupal site']]
  }
}