class postgresql::server ($version = '8.4',
	$listen_addresses = 'localhost',
	$max_connections = 100,
	$shared_buffers = '24MB',
	$package_to_install = '',
	$clean = false,
	$pg_hba_access_rules =
	['local   all         all                               ident',
	'host    all         all         127.0.0.1/32          ident',
	'host    all         all         ::1\/128               ident'],
	$conf_track_counts_value = 'off',
	$conf_autovacuum_value = 'off',
	$conf_max_prepared_transactions_value = '0',
	$conf_max_connections_value = '100',
	$conf_shared_buffers_value = '32MB') {
	$confpath = $::operatingsystem ? {
		'redhat' => "/var/lib/pgsql/data",
		'centos' => "/var/lib/pgsql/data",
		default => "/etc/postgresql/${version}/main",
	}
	class {
		'postgresql::client' :
			version => $version,
	}
	Class['postgresql::server'] -> Class['postgresql::client'] if
	$package_to_install == '' {
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
		exec {
			"reinitialize_pgsql_server" :
				command => "rm -rf $confpath ; /etc/init.d/postgresql initdb",
				path => ["/bin", "/sbin"],
				cwd => "/var",
				require => Package[$pkgname],
		}
		$srv_subscriptions = [File['pg_hba.conf'], File['postgresql.conf']]
	}
	else {
		exec {
			"reinitialize_pgsql_server" :
				command =>
				"echo \"puppet: postgresql-module: clean was set to false -> no reinitialization of data folder performed\"",
				path => ["/bin", "/sbin"],
				cwd => "/var",
				require => Package[$pkgname],
		}
		$srv_subscriptions = [Package[$pkgname], File['pg_hba.conf'],
		File['postgresql.conf']]
	}
	file {
		'pg_hba.conf' :
			path => "$confpath/pg_hba.conf",
			content => template('postgresql/pg_hba.conf.erb'),
			mode => '0640',
			require => [Package[$pkgname], Exec["reinitialize_pgsql_server"]]
	}

	##postgresql.conf prepare vars start#
	if $conf_autovacuum_value != 'off' {
		$cfg_autovacuum = ''
	}
	else {
		$cfg_autovacuum = '#'
	}
	if $conf_track_counts_value != 'off' {
		$cfg_track_counts = ''
	}
	else {
		$cfg_track_counts = '#'
	}
	if $conf_max_prepared_transactions_value != '0' {
		$cfg_max_prepared_transactions = ''
	}
	else {
		$cfg_max_prepared_transactions = '#'
	}

	##postgresql.conf prepare vars end#
	case $operationsystem {
		redhat, centos : {
			$os_conf_file_suffix = '.rhel'
		}
		default : {
			$os_conf_file_suffix = ''
		}
	}
	file {
		'postgresql.conf' :
			path => "$confpath/postgresql.conf",
			content => template("postgresql/postgresql.conf$os_conf_file_suffix.erb"),
			require => [Package[$pkgname], Exec["reinitialize_pgsql_server"]]
	}
	service {
		"postgresql" :
			ensure => running,
			enable => true,
			hasstatus => true,
			hasrestart => true,
			subscribe => $srv_subscriptions,
	}
}
