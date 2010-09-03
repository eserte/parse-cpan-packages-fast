#!/usr/bin/env perl

use strict;
use Test::More;

my $real_tests = 15;
plan tests => 1 + $real_tests;

use_ok 'Parse::CPAN::Packages::Fast';

my $packages_file = eval { Parse::CPAN::Packages::Fast->_default_packages_file };
SKIP: {
    skip "Cannot get default CPAN packages index file", $real_tests
	if !-r $packages_file || -z $packages_file;

    my $pcp = Parse::CPAN::Packages::Fast->new;
    isa_ok($pcp, 'Parse::CPAN::Packages::Fast');

    cmp_ok($pcp->package_count, ">", 10000);
    cmp_ok($pcp->distribution_count, ">", 10000);

    my $package = $pcp->package("Kwalify");
    isa_ok($package, 'Parse::CPAN::Packages::Fast::Package');
    is($package->package, 'Kwalify');
    like($package->prefix, qr{^S/SR/SREZIC/Kwalify-});

    my $dist = $package->distribution;
    isa_ok($dist, 'Parse::CPAN::Packages::Fast::Distribution');
    is($dist->dist, 'Kwalify');
    like($dist->prefix, qr{^S/SR/SREZIC/Kwalify-});

    my @dist_packages = $dist->contains;
    cmp_ok(@dist_packages, ">=", 1, "At least one package found in distribution");
    my($kwalify_package) = grep { $_->package eq 'Kwalify' } @dist_packages;
    isa_ok($kwalify_package, 'Parse::CPAN::Packages::Fast::Package', 'Found Kwalify package in dist');

    ok($pcp->latest_distribution('Kwalify'), 'Find latest Kwalify');
    ok($pcp->latest_distribution('Catalyst-Runtime'), 'Find latest Catalyst-Runtime');

    my @dists = map { $_->dist } $pcp->latest_distributions;
    cmp_ok(scalar(@dists), ">", 10000, 'Reasonable count of latest distribution');
    is($pcp->latest_distribution_count, scalar(@dists));
}
