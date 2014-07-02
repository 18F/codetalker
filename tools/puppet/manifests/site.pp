user {'codetalker':
    groups => ['sudo'],
    ensure => present,
    managehome => true,
    shell => '/bin/bash',
  }

  Exec {
      path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/node/node-default/bin/" ],
      timeout   => 0,
      cwd		  => "/vagrant",
  }

  class { 'apt':
    always_apt_update    => true,
    update_timeout       => undef
  }

  #Set system timezone to UTC
  class { "timezone":
    timezone => 'UTC',
  }

  package { ['sass', 'compass']:
    ensure => 'installed',
    provider => 'gem',
  }

  #Install Node and NPM
  class { 'nodejs':
    version => 'stable',
  }

  exec { 'install_node_commandline_tools':
    command   => "npm install -g grunt-cli bower forever",
    require     => Class['nodejs'],
  }->
    exec { 'install_bower_dependencies':
    command   => "bower install --quiet",
    user		=> "codetalker",
  }->
  exec { 'install_server':
    command   => "npm install",
    require   => Class['nodejs'],
  }->exec { 'start':
      command   => "forever start server.js",
      unless    => "ps -ef | grep '[f]orever'",
  }