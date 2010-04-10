# -*- cperl -*-
use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(NAME => 'Parse::CPAN::Packages::Fast',
	      VERSION_FROM => 'lib/Parse/CPAN/Packages/Fast.pm',
	      PREREQ_PM => { 'version'            => 0,
			     'CPAN::DistnameInfo' => 0,
			     'PerlIO::gzip'       => 0,
			   },
	     );
