# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include hiera_ssm_paramstore
class hiera_ssm_paramstore (
  String $package_name,
){

  $provider = $::environment ? {
    'vagrant' => puppet_gem,
    default   => puppetserver_gem,
  }

  package { $package_name:
    ensure   => present,
    provider => $provider,
  }

}
