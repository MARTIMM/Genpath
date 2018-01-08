use v6;
use Genpath::Plugin;

class Genpath::Plugin::Wget is Genpath::Plugin {

  #-----------------------------------------------------------------------------
  method identity ( --> Str ) {

    'Wget';
  }

  #-----------------------------------------------------------------------------
#  method command ( --> Str ) {
#
#    '/usr/bin/wget';
#  }

  #-----------------------------------------------------------------------------
  method run-execute ( Str:D $command-line --> Bool ) {

#say "command: $command-line";
    $command-line ~~ m/^ <-[:]>+ '://' (<-[/]>+) '/' /;
    my $server = $/[0];
#note $server;

    my Proc $proc = shell '/usr/bin/wget --referer=$server ' ~ $command-line;
    return $proc.exitcode() == 0 ?? True !! False;
  }
}
