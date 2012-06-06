define postgresql::database($owner, $charset='UTF8', $ensure=present) {
  $dbexists = "psql -ltA | grep '^${name}|'"

  if $ensure == 'present' {

    exec { "createdb $name":
      command => "createdb -O ${owner} -E ${charset} ${name}",
      user    => 'postgres',
      unless  => $dbexists,
      path => ["/bin", "/sbin", "/usr/bin"],
      require => Postgresql::User[$owner],
    }


  } elsif $ensure == 'absent' {

    exec { "dropdb $name":
      command => "dropdb ${name}",
      user    => 'postgres',
      onlyif  => $dbexists,
      path => ["/bin", "/sbin", "/usr/bin"],
      before  => Postgresql::User[$owner],
    }
  }
}
