user {'codetalker':
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

  #Install Node and NPM
  class { 'nodejs':
    version => 'stable',
  }
  
  package {['grunt-cli', 'bower', 'forever']:
    ensure      => present,
    provider    => 'npm',
    require     => Class['nodejs'],
  }->
  exec { 'install_compass':
    command   => "gem install compass",
    unless    => "gem search -i compass",
  }->
    exec { 'install_bower':
    command   => "bower install --quiet",
    cwd		  => "/vagrant",
  }->
  exec { 'install_server':
    command   => "npm install",
    cwd       => "/vagrant",
    require   => Class['nodejs'],
  }->exec { 'start':
      command   => "forever start server.js",
      cwd       => "/vagrant",
      unless    => "ps -ef | grep '[f]orever'",
  }