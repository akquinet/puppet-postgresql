class postgresql::server ($version = '8.4',
	$listen_addresses = 'localhost',
	$max_connections = 100,
	$shared_buffers = '24MB',
	$package_to_install = '',
	$clean = false,
	$pg_hba_access_rules = [
'local   all         all                               ident',
'host    all         all         127.0.0.1/32          ident',
'host    all         all         ::1\/128               ident'
]) {
	$confpath = $::operatingsystem ? {
			'redhat' => "/var/lib/pgsql/data",
			'centos' => "/var/lib/pgsql/data",
			default => "/etc/postgresql/${version}/main",
		}
	
	class {
		'postgresql::client' :
			version => $version,
	}
	Class['postgresql::server'] -> Class['postgresql::client'] 
	
	if	$package_to_install == '' {
		$pkgname = $::operatingsystem ? {
			'redhat' => "postgresql-server",
			'centos' => "postgresql-server",
			default => "postgresql-${version}",
		}
	}
	else {
		$pkgname = "$package_to_install"
	}
	package {
		"${pkgname}" :
			ensure => present,
	}
	File {
		owner => 'postgres',
		group => 'postgres',
	}
		
	if $clean {
		exec { "reinitialize_pgsql_server" :
			command => "rm -rf $confpath ; /etc/init.d/postgresql initdb",
			path => ["/bin", "/sbin"],
			cwd => "/var",
			require => Package[$pkgname],
		}
	} else {
		exec { "reinitialize_pgsql_server" :
			command => "echo \"puppet: postgresql-module: clean was set to false -> no reinitialization of data folder performed\"",
			path => ["/bin", "/sbin"],
			cwd => "/var",
			require => Package[$pkgname],
		}
	}
	
	file {
		'pg_hba.conf' :
			path => "$confpath/pg_hba.conf",
			content => template('postgresql/pg_hba.conf.erb'),
			mode => '0640',
			require => [Package[$pkgname],Exec["reinitialize_pgsql_server"]]
	}
	file {
		'postgresql.conf' :
			path => "$confpath/postgresql.conf",			
			require => [Package[$pkgname],Exec["reinitialize_pgsql_server"]]
	}
	
	service {
		"postgresql" :
			ensure => running,
			enable => true,
			hasstatus => true,
			hasrestart => true,
			subscribe => [Package[$pkgname], File['pg_hba.conf'],
			File['postgresql.conf']],
	}
}
