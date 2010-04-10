#!/usr/bin/perl
# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 2009,2010 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven@rezic.de
# WWW:  http://www.rezic.de/eserte/
#

use strict;
use warnings;

######################################################################

{
    package Parse::CPAN::Packages::Fast;

    our $VERSION = '0.02';

    use PerlIO::gzip;
    use version;

    sub _default_packages_file {
	my($class) = @_;
	require CPAN;
	no warnings 'once';
	local $CPAN::Be_Silent = 1;
	CPAN::HandleConfig->load;
	my $packages_file = $CPAN::Config->{keep_source_where} . "/modules/02packages.details.txt.gz";
	$packages_file;
    }

    sub new {
	my($class, $packages_file) = @_;

	if (!$packages_file) {
	    $packages_file = $class->_default_packages_file;
	    if (!$packages_file) {
		die "packages file not specified and cannot be determined from CPAN.pm configuration";
	    }
	}

	my %pkg_to_dist;
	my %dist_to_pkgs;
	my %pkg_ver;

	open my $FH, "<:gzip", $packages_file
	    or die "Can't open $packages_file: $!";
	# overread header
	while(<$FH>) {
	    last if /^$/;
	}
	# read payload
	while(<$FH>) {
	    my($pkg, $ver, $dist) = split;
	    $pkg_to_dist{$pkg} = $dist;
	    $pkg_ver{$pkg} = $ver;
	    push @{ $dist_to_pkgs{$dist} }, $pkg;
	}
	
	bless { pkg_to_dist  => \%pkg_to_dist,
		dist_to_pkgs => \%dist_to_pkgs,
		pkg_ver      => \%pkg_ver,
	      }, $class;
    }

    sub package {
	my($self, $package_name) = @_;
	die "Package $package_name does not exist" if !exists $self->{pkg_ver}{$package_name}; # XXX die or not?
	Parse::CPAN::Packages::Fast::Package->new($package_name, $self);
    }

    sub packages {
	my $self = shift;
	keys %{ $self->{pkg_ver} };
    }

    sub package_count {
	my $self = shift;
	scalar keys %{ $self->{pkg_ver} };
    }

    sub distributions {
	my $self = shift;
	map { Parse::CPAN::Packages::Fast::Distribution->new($_) } keys %{ $self->{dist_to_pkgs} };
    }

    sub distribution_count {
	my $self = shift;
	my @dists = $self->distributions;
	scalar @dists;
    }

    sub latest_distribution {
	my($self, $distribution_name) = @_;
	my @candidates;
	for my $candidate (keys %{ $self->{dist_to_pkgs} }) {
	    if ($candidate =~ m{/\Q$distribution_name}) {
		my $d = Parse::CPAN::Packages::Fast::Distribution->new($candidate);
		if ($d->dist eq $distribution_name) {
		    push @candidates, $d;
		}
	    }
	}
	return if !@candidates; # XXX die or not?
	my $best_candidate = pop @candidates;
	my $best_candidate_version = version->new($best_candidate->version);
	for my $candidate (@candidates) {
	    my $this_version = version->new($candidate->version);
	    if ($best_candidate_version < $this_version) {
		$best_candidate = $candidate;
		$best_candidate_version = $this_version;
	    }
	}
	$best_candidate;
    }

    sub latest_distributions {
	my $self = shift;
	my %latest_dist;
	for my $pathname (keys %{ $self->{dist_to_pkgs} }) {
	    my $d = Parse::CPAN::Packages::Fast::Distribution->new($pathname);
	    my $dist = $d->dist;
	    next if !defined $dist;
	    if (!exists $latest_dist{$dist}) {
		$latest_dist{$dist} = $d;
	    } else {
		no warnings;
		if (eval { version->new($latest_dist{$dist}->version) < version->new($d->version) }) {
		    $latest_dist{$dist} = $d;
		}
	    }
	}
	values %latest_dist;
    }

    sub latest_distribution_count {
	my $self = shift;
	my @dists = $self->latest_distributions;
	scalar @dists;
    }
}

######################################################################

{

    package Parse::CPAN::Packages::Fast::Package;

    our $VERSION = $Parse::CPAN::Packages::Fast::VERSION;

    # Use inside-out technique for this member, to hide it in dumps etc.
    my %obj_to_packages;

    sub new {
	my($class, $package_name, $packages) = @_;
	my $self = bless { package  => $package_name,
			   version  => $packages->{pkg_ver}{$package_name},
			 }, 'Parse::CPAN::Packages::Fast::Package';
	$obj_to_packages{$self} = $packages;
	$self;
    }

    for my $method (qw(package version)) {
	no strict 'refs';
	*{$method} = sub { shift->{$method} };
    }

    sub distribution {
	my $self = shift;
	my $packages = $obj_to_packages{$self};
	my $dist = $packages->{pkg_to_dist}->{$self->package};
	Parse::CPAN::Packages::Fast::Distribution->new($dist);
    }

# XXX prefix
#  print $d->prefix, "\n";    # L/LB/LBROCARD/Acme-Colour-1.00.tar.gz

    sub DESTROY {
	my $self = shift;
	delete $obj_to_packages{$self};
    }
}

######################################################################

{
    package Parse::CPAN::Packages::Fast::Distribution;

    our $VERSION = $Parse::CPAN::Packages::Fast::VERSION;

    use base qw(CPAN::DistnameInfo);
    
# prefix

    # Methods found in original Parse::CPAN::Packages::Distribution
    sub contains {
	die "NYI";
    }

    sub add_package {
	die "NYI";
    }

    # Would be nice to have:
    sub is_latest_distribution {
	die "NYI";
    }
}

######################################################################

1;

__END__

=head1 NAME

Parse::CPAN::Packages::Fast - parse CPAN's package index

=head1 SYNOPSIS

    use Parse::CPAN::Packages::Fast;

    my $p = Parse::CPAN::Packages::Fast->new;
    ## or alternatively, if CPAN.pm is not configured:
    # my $p = Parse::CPAN::Packages::Fast->new("/path/to/02packages.details.txt.gz");

    my $m = $p->package("Kwalify");
    # $m is a Parse::CPAN::Packages::Fast::Package object
    print $m->package, "\n";   # Kwalify
    print $m->version, "\n";   # 1.21

    my $d = $m->distribution;
    # $d is a Parse::CPAN::Packages::Fast::Distribution object
    print $d->dist,    "\n";   # Kwalify
    print $d->version, "\n";   # 1.21

=head1 DESCRIPTION

This is a largely API compatible rewrite of L<Parse::CPAN::Packages>.

Notable differences are

=over

=item * The methods contains and add_package of
Parse::CPAN::Packages::Fast::Distribution are not implemented

=item * Parse::CPAN::Packages::Fast::Distribution is really a
L<CPAN::DistnameInfo> (but this one is compatible with
Parse::CPAN::Packages::Distribution>

=back

=head2 WHY?

Calling C<Parse::CPAN::Packages>' constructor is quite slow and takes
about 10 seconds on my machine. In contrast, the reimplementation just
takes a second.

I did some benchmarking of the original module and found no obvious
weak point to speed it up. Moose is used here, but does not seem to
cause the problem. I suspect that the real problem is just heavy use
of method calls.

=head1 SEE ALSO

L<Parse::CPAN::Packages>, L<CPAN::DistnameInfo>.

=cut
