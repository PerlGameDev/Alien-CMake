package My::Utility;
use strict;
use warnings;
use base qw(Exporter);

our @EXPORT_OK = qw(check_prebuilt_binaries check_src_build find_CMake_dir find_file sed_inplace);
use Config;
use File::Spec::Functions qw(splitdir catdir splitpath catpath rel2abs);
use File::Find qw(find);
use File::Copy qw(cp);
use Cwd qw(realpath);

our $cc = $Config{cc};

# cmake-2.8.4-AIX-powerpc.tar.gz - 1a7692a1c3565770aa2c5fe620ccb477c221349c
# cmake-2.8.4-IRIX64-64.tar.gz - 286dc02395545c62eb878fc6662a4ea666eb8046
# cmake-2.8.4-IRIX64-n32.tar.gz - 26b3e27c77bb9a95a85a9f100b6129776a2a8cef
# cmake-2.8.4-SunOS-sparc.tar.gz - 068c20450ee7e3074ac4c8396e3fa73f28aba35d

my $prebuilt_binaries = [
    {
      title    => "Binaries Win/32bit CMake-2.8.4",
      url      => 'http://www.cmake.org/files/v2.8/cmake-2.8.4-win32-x86.zip',
      version  => '2.8.4',
      sha1sum  => '539ce250521d964a8770e0a7362db196dbc97fbc',
      arch_re  => qr/^MSWin32-x(86|64)-multi-thread$/,
      os_re    => qr/^MSWin32$/
    },
    {
      title    => "Binaries Linux/i386 CMake-2.8.4",
      url      => 'http://www.cmake.org/files/v2.8/cmake-2.8.4-Linux-i386.tar.gz',
      version  => '2.8.4',
      sha1sum  => '51112b5e203e07a4430249e6252ec2ec461a3aff',
      arch_re  => qr/(86.*linux|linux.*86)/,
      os_re    => qr/^linux$/
    },
    {
      title    => "Binaries darwin CMake-2.8.4",
      url      => 'http://www.cmake.org/files/v2.8/cmake-2.8.4-Darwin-universal.tar.gz',
      version  => '2.8.4',
      sha1sum  => '190d9e536ed78c756e875747aedcad507fba74a8',
      arch_re  => qr//,
      os_re    => qr/^darwin$/
    },
];

my $source_packs = [
## the first set for source code build will be a default option
#  {
#    title    => "Source code build: CMake 2.1.2 (needs cmake)",
#    dirname  => 'CMake',
#    url      => 'http://box2d.googlecode.com/files/CMake_v2.1.2.zip',
#    sha1sum  => 'b1f09f38fc130ae6c17e1767747a3a82bf8e517f',
#    patches  => [ ],
#  },
## you can add another src build set
];

sub check_prebuilt_binaries
{
  print "Gonna check availability of prebuilt binaries ...\n";
  print "(os=$^O cc=$cc archname=$Config{archname})\n";
  my @good = ();
  foreach my $b (@{$prebuilt_binaries}) {
    if ( ($^O =~ $b->{os_re}) &&
         ($Config{archname} =~ $b->{arch_re}) ) {
      $b->{buildtype} = 'use_prebuilt_binaries';

      push @good, $b;
    }
  }
  #returning ARRAY of HASHREFs (sometimes more than one value)
  return \@good;
}

sub check_src_build
{
  print "Gonna check possibility for building from sources ...\n";
  print "(os=$^O cc=$Config{cc})\n";
  foreach my $p (@{$source_packs}) {
    $p->{buildtype} = 'build_from_sources';
  }
  return $source_packs;
}

sub find_file {
  my ($dir, $re) = @_;
  my @files;
  $re ||= qr/.*/;
  find({ wanted => sub { push @files, rel2abs($_) if /$re/ }, follow => 1, no_chdir => 1 , follow_skip => 2}, $dir);
  return @files;
}

sub find_CMake_dir {
  my $root = shift;
  my ($prefix, $incdir, $libdir);
  return unless $root;

  # try to find 
  my ($found) = find_file($root, qr/[\\\/]cmake(\.exe)?$/i ); # take just the first one
  return unless $found;
  
  # get prefix dir
  my ($v, $d, $f) = splitpath($found);
  my @pp = reverse splitdir($d);
  shift(@pp) if(defined($pp[0]) && $pp[0] eq '');
  if(defined($pp[0]) && $pp[0] eq 'bin') {
    shift(@pp);
    @pp = reverse @pp;
    return (
      catpath($v, catdir(@pp), ''),
      catpath($v, catdir(@pp, 'bin'), ''),
      catpath($v, catdir(@pp, 'share'), ''),
    );
  }
}

sub sed_inplace {
  # we expect to be called like this:
  # sed_inplace("filename.txt", 's/0x([0-9]*)/n=$1/g');
  my ($file, $re) = @_;
  if (-e $file) {
    cp($file, "$file.bak") or die "###ERROR### cp: $!";
    open INPF, "<", "$file.bak" or die "###ERROR### open<: $!";
    open OUTF, ">", $file or die "###ERROR### open>: $!";
    binmode OUTF; # we do not want Windows newlines
    while (<INPF>) {
     eval( "$re" );
     print OUTF $_;
    }
    close INPF;
    close OUTF;
  }
}

1;
