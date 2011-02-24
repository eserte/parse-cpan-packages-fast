# -*- cperl -*-
use 5.006;
use ExtUtils::MakeMaker;

my $eumm_recent_enough = $ExtUtils::MakeMaker::VERSION >= 6.54;

if (!$eumm_recent_enough) {
    *MY::dist_core = sub {
	<<'EOF';
dist :
	$(NOECHO) $(ECHO) "Sorry, use a newer EUMM!"

EOF
    };
}

WriteMakefile(NAME => 'Parse::CPAN::Packages::Fast',
	      VERSION_FROM => 'lib/Parse/CPAN/Packages/Fast.pm',
	      PREREQ_PM => { 'version'            => 0,
			     'CPAN::DistnameInfo' => 0,
			     'PerlIO::gzip'       => 0,
			   },
	      ($eumm_recent_enough ?
	       (META_ADD => { resources => { repository => 'git://github.com/eserte/parse-cpan-packages-fast.git' } }) : ()),
	     );
