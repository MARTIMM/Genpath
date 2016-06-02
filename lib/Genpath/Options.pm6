use v6.c;

use File::HomeDir;
use Config::TOML;

class Genpath::Options {

  has Hash $.config;
  has Str $!config-content;

  #-----------------------------------------------------------------------------
  submethod BUILD ( Str :$config-file is copy = 'genpath.cfg' ) {

    # Read file only once unless file cannot be found. Then there is another
    # opportunity to read it later when file is created.
    #
    if not $!config-content.defined {

      # First try to find 'genpath.cfg' current directory, Then try '.genpath.cfg'
      # and lastly try '.genpath.cfg' in home directory
      #
      if not $config-file.IO ~~ :r {
        $config-file = ".$config-file";
        if not $config-file.IO ~~ :r {
          $config-file = File::HomeDir.my-home ~ "/$config-file";
        }

        else {
          note "Config file not found";
          exit 1;
        }
      }

      # Parse config file if exists
      if $config-file.IO ~~ :r {
        $!config-content = slurp($config-file);
      }
    }

    if $!config-content.defined {

      $!config = from-toml($!config-content);
    }
  }

  #-----------------------------------------------------------------------------
  method config-options (
    Str:D $identity,
    $option-section = 'default'
    --> Array
  ) {

    # Get all options from specified section
    my Hash $os = self!get-options( 'options', $identity, $option-section);

    # Convert into Array
    if $os.elems {
      [ map { $os{$_} ~~ Bool ?? $_ !! "$_=$os{$_}"; }, $os.keys ];
    }

    else {
      [];
    }
  }

  #-----------------------------------------------------------------------------
  method program-control ( Str:D $identity --> Hash ) {

    my Hash $os = %(
      %(self!get-options( 'Genpath', 'Plugin')),
      %(self!get-options( $identity)),
    );
  }

  #-----------------------------------------------------------------------------
  method !get-options ( *@option-keys --> Hash ) {

    my Hash $options = {};
    my Hash $s = $!config;

    for @option-keys -> $option-key {

      $s = $s{$option-key} // {};

      for $s.keys -> $k {
        next if $s{$k} ~~ Hash;

        my Bool $bo = self!bool-option($s{$k});

        # Not a boolean option
        if not $bo.defined {
          $options{$k} = $s{$k};
        }

        # Boolean option and true. False booleans are ignored
        elsif $bo {
          $options{$k} = True;
        }
      }
    }

    $options // {};
  }

  #-----------------------------------------------------------------------------
  # Return values
  # Any) Not boolean/undefined, True) Boolean False, False) Boolean True
  #
  method !bool-option ( $v --> Bool ) {

    if $v ~~ Bool and $v {
      True;
    }

    elsif $v ~~ Bool and not $v {
      False;
    }

    else {
      Bool;
    }
  }
}
