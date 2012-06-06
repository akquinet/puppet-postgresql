define postgresql::database($owner, $charset='UTF8', $ensure=present) {
  $dbexists = "psql -ltA | grep '^${name}|'"

  postgresql::user { $owner:
    ensure => $ensure,
  }

  if $ensure == 'present' {

    exec { "createdb $name":
      command => "createdb -O ${owner} -E ${charset} ${name}",
      user    => 'postgres',
      unless  => $dbexists,
      require => Postgresql::User[$owner],
    }


  } elsif $ensure == 'absent' {

    exec { "dropdb $name":
      command => "dropdb ${name}",
      user    => 'postgres',
      onlyif  => $dbexists,
      before  => Postgresql::User[$owner],
    }
  }
}
