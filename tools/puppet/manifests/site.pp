user {'vagrant':
    # groups => ['sudo'],
    ensure => present,
    # managehome => true,
    # shell => '/bin/bash',
  }

  Exec {
      path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/node/node-default/bin/" ],
      timeout   => 0,
      cwd		  => "/vagrant",
  }

  package { 'curl':
    ensure => 'installed'
  }

  package { ['sass', 'compass']:
    ensure => 'installed',
    provider => 'gem',
  }

  #Install Node and NPM
  class prepare {
  class { 'apt': }
  apt::ppa { 'ppa:chris-lea/node.js': }
}
include prepare
 
package {'nodejs': ensure => present, require => Class['prepare'],}

  # class { 'nodejs':
  #   version => 'stable',
  #   make_install => 'false',
  # }->
  # file{'make_node_local':
  # path  => '/usr/local/node/node-default',  
  # ensure => 'directory',
  # mode  => '700',
  # owner => 'vagrant',
  # group => 'vagrant',
  # recurse => 'inf',
  # }

  #Install npm packages globally
   exec { 'install_node_cli_tools':
     command => 'sudo npm install -g grunt-cli bower forever',
     require   => Class['nodejs'],
     user => 'vagrant',
   }->
     file{'set_node_ownership':
  path  => '/home/vagrant/.npm',  
  ensure => 'directory',
  mode  => '700',
  owner => 'vagrant',
  group => 'vagrant',
  recurse => 'inf',
  }
   ->
  exec { 'install_bower_dependencies':
     command   => "bower install --quiet",
     user    => 'vagrant',
   }->
   exec { 'install_server':
     command   => "npm install",
     require   => Class['nodejs'],
     user    => 'vagrant',
   }
  #  ->exec { 'start':
  #      command   => "forever start server.js",
  #      unless    => "ps -ef | grep '[f]orever'",
  #              user    => 'vagrant',      
  # }