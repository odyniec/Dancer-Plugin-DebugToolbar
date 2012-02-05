use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share 'share';

my $preop =
    'perldoc -uT $(VERSION_FROM) | tee $(DISTVNAME)/README.pod > README.pod;' .
    'pod2text README.pod | tee $(DISTVNAME)/README > README';

WriteMakefile(
    NAME                => 'Dancer::Plugin::DebugToolbar',
    AUTHOR              => q{Michal Wojciechowski <odyniec@cpan.org>},
    VERSION_FROM        => 'lib/Dancer/Plugin/DebugToolbar.pm',
    ABSTRACT_FROM       => 'lib/Dancer/Plugin/DebugToolbar.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    CONFIGURE_REQUIRES => {
        'File::ShareDir::Install'   => 0,
    },
    PREREQ_PM => {
        'Test::More' => 0,
        'Dancer'     => 1.3070,
        'File::ShareDir'    => 1.0,
        'File::ShareDir::Install'   => 0,
        'Tie::Hash::Indexed'    => 0,
    },
    dist => {
        COMPRESS => 'gzip -9f',
        SUFFIX => 'gz',
        PREOP => $preop
    },
    clean               => { FILES => 'Dancer-Plugin-DebugToolbar-*' },
);
    
package MY;
use File::ShareDir::Install;

sub MY::postamble
{
    my $self = shift;
    my @ret = File::ShareDir::Install::postamble($self);
    
    return join "\n", @ret;
}
