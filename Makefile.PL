# -*- cperl -*-
use 5.006;
use ExtUtils::MakeMaker;

eval {
    if ((getpwuid($<))[0] eq 'eserte' && $ExtUtils::MakeMaker::VERSION < 6.54) {
	warn <<EOF;
**********************************************************************
* WARNING:
* ExtUtils::MakeMaker too old. META.yml will be imcomplete
**********************************************************************
EOF
    }
};

WriteMakefile(NAME => 'Parse::CPAN::Packages::Fast',
	      VERSION_FROM => 'lib/Parse/CPAN/Packages/Fast.pm',
	      PREREQ_PM => { 'version'            => 0,
			     'CPAN::DistnameInfo' => 0,
			     'PerlIO::gzip'       => 0,
			   },
	      ($ExtUtils::MakeMaker::VERSION >= 6.54 ?
	       (META_ADD => { resources => { repository => 'git://github.com/eserte/parse-cpan-packages-fast.git' } }) : ()),
	     );
