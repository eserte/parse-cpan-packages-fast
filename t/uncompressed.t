use strict;
use warnings 'FATAL', 'all';
use FindBin;
use lib $FindBin::RealBin;

use File::Temp ();
use Test::More;

use TestUtil;

use Parse::CPAN::Packages::Fast;

my $packages_file = my_default_packages_file;
if (!$packages_file) {
    diag "INFO: Can't get default packages file";
    plan skip_all => 'Cannot get default CPAN packages index file';
    exit;
}

plan 'no_plan';

my $tmpfile = File::Temp->new;
my $fh = IO::Uncompress::Gunzip->new($packages_file);
{
    local $/ = \4096;
    while(<$fh>) {
	$tmpfile->print($_);
    }
    $tmpfile->close;
}

my $pcp = Parse::CPAN::Packages::Fast->new("$tmpfile");
isa_ok $pcp, 'Parse::CPAN::Packages::Fast';

cmp_ok $pcp->package_count, '>', 10000;
cmp_ok $pcp->distribution_count, '>', 10000;

my $package = $pcp->package("Kwalify");
isa_ok $package, 'Parse::CPAN::Packages::Fast::Package';
is $package->package, 'Kwalify';
like $package->prefix, qr{^S/SR/SREZIC/Kwalify-};
