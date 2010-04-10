#!/usr/bin/env perl

use strict;
use Test::More;

my $real_tests = 11;
plan tests => 1 + $real_tests;

use_ok 'Parse::CPAN::Packages::Fast';

my $packages_file = Parse::CPAN::Packages::Fast->_default_packages_file;
SKIP: {
    skip "Cannot get the default packages index file", $real_tests
	if !-r $packages_file || -z $packages_file;

    my $pcp = Parse::CPAN::Packages::Fast->new;
    isa_ok($pcp, 'Parse::CPAN::Packages::Fast');

    cmp_ok($pcp->package_count, ">", 10000);
    cmp_ok($pcp->distribution_count, ">", 10000);

    my $package = $pcp->package("Parse::CPAN::Packages");
    isa_ok($package, 'Parse::CPAN::Packages::Fast::Package');
    is($package->package, 'Parse::CPAN::Packages');

    my $dist = $package->distribution;
    isa_ok($dist, 'Parse::CPAN::Packages::Fast::Distribution');
    is($dist->dist, 'Parse-CPAN-Packages');

    ok($pcp->latest_distribution('Kwalify'));
    ok($pcp->latest_distribution('Catalyst-Runtime'));

    my @dists = map { $_->dist } $pcp->latest_distributions;
    cmp_ok(scalar(@dists), ">", 10000);
    is($pcp->latest_distribution_count, scalar(@dists));
}
