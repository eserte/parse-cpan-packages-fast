# -*- perl -*-

package TestUtil;

use strict;
use Exporter 'import';
use Cwd;

our @EXPORT = qw(my_default_packages_file);

sub my_default_packages_file {
    if ($ENV{PERL_AUTHOR_TEST}) {
	return Parse::CPAN::Packages::Fast->_default_packages_file_interactive;
    }

    my $packages_file = getcwd() . '/t/02packages.details.txt.gz';
    return undef if $packages_file && (!-r $packages_file || -z $packages_file);
    $packages_file;
}

1;

__END__
