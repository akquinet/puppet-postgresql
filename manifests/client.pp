class postgresql::client ($version) {
	$clpkgname = $::operatingsystem ? {
		'redhat' => "postgresql",
		'centos' => "postgresql",
		default => "postgresql-${version}",
	}
	package {
		"$clpkgname" :
			ensure => present,
	}
}
