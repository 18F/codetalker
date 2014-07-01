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

  #Install Node and NPM
  class { 'nodejs':
    version => 'stable',
  }
  
  package {['grunt-cli', 'forever']:
    ensure      => present,
    provider    => 'npm',
    require     => Class['nodejs'],
  }->
  exec { 'install_compass':
    command   => "gem install compass",
    unless    => "gem search -i compass",
  }->
    exec { 'install_bower':
    command   => "gem install bower",
    unless	  => "gem search -i bower",
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
      user		=> "codetalker",
  }