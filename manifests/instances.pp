# Create all virtual hosts from hiera
class role_drupal::instances (
    $instances,
)
{
  create_resources('apache::vhost', $instances)
}
