use v6;
use Genpath::Options;

class Genpath::Plugin {

  has Hash $!module-names;
  has Array $.run-args;
  has Str $.command-path;
  has Str $!config-file;
  has Str $!current-dir;

  #-----------------------------------------------------------------------------
  submethod BUILD ( Str :$config-file = 'genpath.cfg' ) {

    $!config-file = $config-file;
    $!module-names = {};
    $!run-args = [];

    $!current-dir = $*CWD.Str;
  }

  #-----------------------------------------------------------------------------
  method install-plugin ( Str:D $module-name, Str :$plugin-path = '' ) {

    if $!module-names{$module-name}:!exists {
      if ?$plugin-path {
        my $repository = CompUnit::Repository::FileSystem.new(
          :prefix($plugin-path)
        );

        CompUnit::RepositoryRegistry.use-repository($repository);
      }

#note "Load '$module-name'";
      (try require ::($module-name)) === Nil
           and say "Failed to load $module-name at $?LINE";

#require ::($module-name);
#say ::($module-name).new.perl;

#say "Module name ", ::($module-name).^name;
#say "Module methods", ::($module-name).^methods;

      if ::($module-name) ~~ Failure {
        die ::($module-name);
      }

      $!module-names{$module-name} = ::($module-name);
    }
  }

  #-----------------------------------------------------------------------------
  method generate-object ( Str:D $module-name --> Genpath::Plugin ) {

#say "Module init $module-name: ", ::($module-name).perl;
    ::($module-name).Bool;
    my Genpath::Plugin $object;
    if $!module-names{$module-name}:exists {
      $object = ::($module-name).new;
    }
#say "Module init: ", $object.perl;

    $object;
  }

  #-----------------------------------------------------------------------------
  method run-init ( Str:D :$option-section ) {

    # Get options from configuration
    my Genpath::Options $o .= new(:$!config-file);
    my Array $cfg-options = $o.config-options(
      self.identity(),
      $option-section
    );

    $!run-args.push: |@($cfg-options);
    $!command-path = self.command;


    my Hash $program-control = $o.program-control(self.identity());
    if $program-control<workdir>:exists {
      if $program-control<workdir>.IO ~~ :d {
        chdir $program-control<workdir>;
      }

      else {
        die "Directory $program-control<workdir> not found";
      }
    }
  }

  #-----------------------------------------------------------------------------
  method run ( Str:D $request-text --> Bool ) {

    my Bool $run-ok = True;

    if ? $!command-path {
      my Str $command-line =
         [~] "'$.command-path'",
             ' ',
             (map { "'$_' " unless $_ ~~ m/^ \s* $/ }, @$!run-args),
             $request-text;

      $run-ok = self.run-execute($command-line);
    }

    else {
      die "Command path not defined";
    }

    $run-ok;
  }

  #-----------------------------------------------------------------------------
  method run-finish ( ) {

    chdir $!current-dir;
  }

  #-----------------------------------------------------------------------------
  # Absolute methods to be defined by child classes
  #
  method identity ( --> Str ) { ... }
  method command ( --> Str ) { ... }
  method run-execute ( Str:D $command-line --> Bool ) { ... }
}
