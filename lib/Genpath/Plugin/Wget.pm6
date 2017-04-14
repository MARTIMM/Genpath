use v6;
use Genpath::Plugin;

class Genpath::Plugin::Wget is Genpath::Plugin {

  #-----------------------------------------------------------------------------
  method identity ( --> Str ) {

    'Wget';
  }

  #-----------------------------------------------------------------------------
  method command ( --> Str ) {

    '/usr/bin/wget';
  }

  #-----------------------------------------------------------------------------
  method run-execute ( Str:D $command-line --> Bool ) {

#say "command: $command-line";
    my Proc $proc = shell $command-line;
    return $proc.exitcode() == 0 ?? True !! False;
  }
}
