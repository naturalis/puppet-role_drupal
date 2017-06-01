# Create all virtual hosts from hiera
class role_drupal::instances (
)
{
  create_resources('apache::vhost', $role_drupal::instances)
  if ($role_drupal::enablessl == true) {
    create_resources('apache::vhost', $role_drupal::sslinstances)
  }
}
