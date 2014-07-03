user {'vagrant':
    groups => ['sudo'],
    ensure => present,
    managehome => true,
    shell => '/bin/bash',
  }

  Exec {
    path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/node/node-default/bin/" ],
    environment => [ "HOME=/home/vagrant" ],
#    timeout   => 0,
    cwd		  => "/vagrant",
  }

  package { 'curl':
  ensure => 'installed'
  }

 package { ['sass', 'compass']:
  ensure => 'installed',
    provider => 'gem',
  }

#   #Install Node and NPM
  class prepare {
    class { 'apt': }
      apt::ppa { 'ppa:chris-lea/node.js': }
    }
    include prepare

    package {'nodejs': ensure => present, require => Class['prepare'],}

#   #Install npm packages globally
  exec { 'install_node_cli_tools':
   command => 'sudo npm install -g grunt-cli bower forever',
   require   => Package['nodejs'],
   user => 'vagrant',
 }


 file{'set_node_ownership':
  path  => '/home/vagrant/.npm',  
ensure => 'directory',
mode  => '755',
owner => 'vagrant',
group => 'vagrant',
recurse => 'true',
recurselimit => 9,
require => Exec['install_node_cli_tools'],
}

exec { 'install_bower_dependencies':
 command   => "bower install --quiet",
 user    => 'vagrant',
 require  => File['set_node_ownership'],
}

exec { 'install_server':
 command   => "npm install",
 require   => Exec['install_bower_dependencies'],
 user    => 'vagrant',
}

exec { 'start':
 command   => "forever start server.js",
 unless    => "ps -ef | grep '[f]orever'",
   user    => 'vagrant',      
   require => Exec['install_server'],
 }
