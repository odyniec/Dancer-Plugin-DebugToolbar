use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share 'share';

WriteMakefile(
    NAME                => 'Dancer::Plugin::DebugToolbar',
    AUTHOR              => q{Michal Wojciechowski <odyniec@cpan.org>},
    VERSION_FROM        => 'lib/Dancer/Plugin/DebugToolbar.pm',
    ABSTRACT_FROM       => 'lib/Dancer/Plugin/DebugToolbar.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Dancer'     => 1.3070,
        'File::ShareDir'    => 1.0,
        'File::ShareDir::Install'   => 0,
        'Tie::Hash::Indexed'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Dancer-Plugin-DebugToolbar-*' },
);
    
package MY;
use File::ShareDir::Install qw(postamble);