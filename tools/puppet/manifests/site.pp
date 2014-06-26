#Install Node and NPM
class { 'nodejs':
    version => 'v0.10.25',
    make_install => false,
}

package {'grunt-cli':
  provider    => 'npm',
}

package {'forever':
  provider  => 'npm',
}

user {'evented':
  groups => ['sudo'],
  ensure => present,
  managehome => true,
  shell => '/bin/bash',
}

Exec {
    path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/node/node-default/bin/" ],
    timeout   => 0,
}

class { 'apt':
  always_apt_update    => true,
  update_timeout       => undef
}

#Set system timezone to UTC
class { "timezone":
  timezone => 'UTC',
}

package { [
    'curl',
    'wget',
  ]:
  ensure  => 'installed',
}

exec { 'npm_install':
  command   => "npm install",
  require   => Class['nodejs']
}
