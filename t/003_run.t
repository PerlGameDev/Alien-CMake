
use Test::More;
use Alien::CMake;
use File::Spec;

plan tests => 1;

my $devnull  = File::Spec->devnull();
my $path_sep = $^O eq 'MSWin32' ? ';' : ':';
$ENV{'PATH'} = $ENV{'PATH'} . $path_sep . Alien::CMake->config('bin');
my $ver      = `cmake --version 2> $devnull`;

ok( $ver =~ /cmake version ([\d\.]+)/, "cmake version is $1" );
