use v6;
use Genpath::Plugin;

class Genpath::Plugin::Echo is Genpath::Plugin {

  #-----------------------------------------------------------------------------
  method identity ( --> Str ) {

    'Echo';
  }

  #-----------------------------------------------------------------------------
  method command ( --> Str ) {

    '/usr/bin/echo';
  }

  #-----------------------------------------------------------------------------
  method run-execute ( Str:D $command-line --> Bool ) {

    my Bool $exit-ok = False;
    my Proc $proc;
    if $command-line ~~ m:s/ '--version' / {
      $proc = shell self.command-path ~ " --version";
    }

    elsif $command-line ~~ m:s/ '--help' / {
      $proc = shell self.command-path ~ " --help";
    }

    else {
      $proc = shell $command-line;
      $exit-ok = $proc.exitcode == 0 ?? True !! False;
    }

    return $exit-ok;
  }
}
