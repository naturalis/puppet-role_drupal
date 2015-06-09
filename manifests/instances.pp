# Create all virtual hosts from hiera
class role_drupal::instances (
    $instances  = undef,
)
{
  create_resources('apache::vhost', $instances)
}
