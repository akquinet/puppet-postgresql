class postgresql::server ($version = '8.4',
	$listen_addresses = 'localhost',
	$max_connections = 100,
	$shared_buffers = '24MB',
	$package_to_install = '',
	$clean = false) {
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
	
	
	file {
		'pg_hba.conf' :
			path => "$confpath/pg_hba.conf",
			source => 'puppet:///modules/postgresql/pg_hba.conf',
			mode => '0640',
			require => Package[$pkgname],
	}
	file {
		'postgresql.conf' :
			path => "$confpath/postgresql.conf",			
			require => Package[$pkgname],
	}
	if $clean {
		exec { "reinitialize pgsql-server" :
			command => "rm -rf $confpath ; /etc/init.d/postgresql initdb",
			path => ["/bin", "/sbin"],
			cwd => "/var",
			require => Package[$pkgname],
		}
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
