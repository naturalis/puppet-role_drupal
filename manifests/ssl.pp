# == Class: role_drupal::ssl
#
# ssl code for enabline ssl with or without letsencrypt
#
# Author Name <hugo.vanduijn@naturalis.nl>
#
#
class role_drupal::ssl (
)
{

# Install modssl when ssl is enabled
  if ($role_drupal::enablessl == true) {
    class { 'apache::mod::ssl':
      ssl_compression => false,
      ssl_options     => [ 'StdEnvVars' ],
    }
  }

# install letsencrypt certs only and crontab
  if ($role_drupal::enableletsencrypt == true) {
    class { ::letsencrypt:
      config => {
        email  => $role_drupal::letsencrypt_email,
        server => $role_drupal::letsencrypt_server,
      }
    }
    letsencrypt::certonly { 'letsencrypt_cert':
      domains       => $role_drupal::letsencrypt_domains,
      manage_cron   => true,
    }
  }
}

