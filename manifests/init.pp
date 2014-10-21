# == Class: autosign_classify
#
# Module to manage auto-signing of certificates and auto-classifying from CSR 
# custom extensions.
#
# === Parameters
#
#
#
# === Examples
#
#  class { autosign_classify:
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#  }
#
# === Authors
#
# Author Name <author@domain.com>
#
# === Copyright
#
# Copyright 2014 Your name here, unless otherwise noted.
#
class autosign_classify (
  $autoclassify_dest    = '/opt/puppet/share/puppet-dashboard/autoclassify.rb',
  $autosign_dest        = '/opt/puppet/bin/autosign.rb',
  $autosigning_template = 'autosign_classify/rightscale.rb.erb',
  $primary              = false,
  $right_api            = undef,
  $right_token          = undef,
  $rsync_ssl_dir        = '/etc/puppetlabs/puppet/ssl/',
  $rsync_user           = 'pe-puppet',
  $secondary_mom        = undef,
) {

  if $::osfamily != 'RedHat' {
    fail("Wrong OS Family, should be RedHat, not ${::osfamily}")
  }

  # variables
  $incron_condition = "${::settings::ssldir}/ca/signed IN_CREATE"
  $incron_ssl_condition = "${::settings::ssldir}/ca/signed IN_CREATE,IN_DELETE,IN_MODIFY"

  ensure_packages(['rsync'])

  if $primary {

    if $secondary_mom {
      file { '/etc/incron.d/sync_certs':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0744',
        content => "${incron_ssl_condition} rsync -apu /etc/puppetlabs/puppet/ssl/* ${rsync_user}@${secondary_mom}:${rsync_ssl_dir}/\n",
        require => Package['incron'],
      }
    }

    file { 'autosigner':
      ensure  => file,
      path    => $autosign_dest,
      owner   => $::settings::user,
      group   => $::settings::group,
      mode    => '0755',
      content => template($autosigning_template),
    }

    ini_setting { 'autosign':
      ensure  => present,
      path    => "${::settings::confdir}/puppet.conf",
      section => 'master',
      setting => 'autosign',
      value   => $autosign_dest,
      require => File['autosigner'],
    }

    package { 'incron':
      ensure => present,
    }

    file { 'autoclassifier':
      ensure => file,
      path   => $autoclassify_dest,
      owner  => 'puppet-dashboard',
      group  => 'root',
      mode   => '0744',
      source => 'puppet:///modules/autosign_classify/autoclassify.rb',
    }

    file { '/etc/incron.d/autoclassify':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0744',
      content => "${incron_condition} ${autoclassify_dest} \$@/\$#",
      require => [Package['incron'],File['autoclassifier']],
    }

    service { 'incrond':
      ensure    => running,
      enable    => true,
      subscribe => File['/etc/incron.d/autoclassify'],
    }
  } else {

    file { '/etc/incron.d/sync_certs':
      ensure  => absent,
    }

    file { 'autosigner':
      ensure => absent,
      path   => $autosign_dest,
    }

    ini_setting { 'autosign':
      ensure  => absent,
      path    => "${::settings::confdir}/puppet.conf",
      section => 'master',
      setting => 'autosign',
      value   => $autosign_dest,
    }

    file { 'autoclassifier':
      ensure => absent,
      path   => $autoclassify_dest,
    }

    file { '/etc/incron.d/autoclassify':
      ensure  => absent,
    }
  }

}
