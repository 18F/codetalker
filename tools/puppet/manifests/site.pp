include "./install.pp"

exec { 'start':
    command   => "forever start server.js",
    cwd       => "/vagrant",
    unless    => "ps -ef | grep '[f]orever'"
}
