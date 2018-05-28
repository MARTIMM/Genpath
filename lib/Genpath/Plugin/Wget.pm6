use v6;
use Genpath::Plugin;

class Genpath::Plugin::Wget is Genpath::Plugin {

  has Str $!command;
  has Bool $!referer = False;

  #-----------------------------------------------------------------------------
  method identity ( --> Str ) {

    'Wget';
  }

  #-----------------------------------------------------------------------------
  method program-config ( Hash:D $program-control ) {

    $!command = $program-control<comand> // '/usr/bin/wget';
    $!referer = $program-control<referer> // False;

    if $program-control<workdir>:exists {
      if $program-control<workdir>.IO ~~ :d {
        chdir $program-control<workdir>;
      }

      else {
        die "Directory $program-control<workdir>.Str() not found";
      }
    }
  }

  #-----------------------------------------------------------------------------
  method run-execute ( Str:D $command-line --> Bool ) {

    my Str $rstr = ' ';
    if $!referer {
      $command-line ~~ m/ ( [ http s?| ftp s? ] '://' <-[/]>+) '/' /;
      my $server = $/[0];
      $rstr = " --referer=$server ";
    }

    my Proc $proc = shell $!command ~ $rstr ~ $command-line;
    return $proc.exitcode() == 0 ?? True !! False;
  }
}
