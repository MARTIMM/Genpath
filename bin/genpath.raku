#!/usr/bin/env raku

use v6;
use Genpath;

sub MAIN (
  *@args, Str :$p = 'Echo', Str :$o = 'default', Bool :$ie = False
) {

  my Str $text = @args.pop;

  # Create genpath object
  my Genpath $g .= new( :$text, :ranges(@args.list),
    :plugin-module($p), :option-section($o)
  );

  $g.ignore-errors = $ie;

  # Then generate all possible lines and send them to the plugin
  $g.redirect-texts;
}

sub USAGE ( ) {

  say Q:to/EOHELP/;

  Generate output to plugin using string and counters

  Usage:
    genpath [options] [<ranges>] text

  Options:
    --ie=<Bool> Ignore errors. Normally when there are errors found by a plugin
                the rest of the fastest running counter is skipped. False by
                default.

    --o=<Str>   Specify an option section, default is 'default'.

    --p=<Str>   Define plugin module name. There are some plugins provided in
                Genpath::Plugin. Default is Genpath::Plugin::Echo.

  Arguments:
    Optional series of ranges and expressions followed by a sprintf-type-text
    which is a string manipulated in such a way that the ranges are substituted
    into that string. See for sprintf documentation at
    http://docs.perl6.org/language/5to6-perlfunc#sprintf and
    http://docs.perl6.org/routine/sprintf and also some examples below.

    E.g. arguments like the following two
         1..4 'count is now %d'

    consists of one counter followind by a sprinf string. The program will
    substitute all values of the couter range into the string to produce;
         count is now 1
         count is now 2
         count is now 3
         count is now 4

  Counters:
    The counters can be of type Range (..), sequence (...), List (,) or
    operator. The range and sequence are simplified operators not able to use ^
    or do calculations in the list before the ... operator. A simple list of
    numbers of characters are possible mixed with ranges.
         2,1.2..4,-1.34           Produces 2.0 1.2 2.2 3.2 -1.34
         1.1,1.44...2.3                    1.1 1.44 1.78 2.12
         1.1,a..c,ab..ae                   1.1 a b c ab ac ad ae
         1.1,1.3...1.8                     1.1 1.3 1.5 1.7

    When using operations on counters you will need at least 2 counter specs.
    One for te range and one for the operation. E.g
         1,5 0+4 'counters are %d and %d'

    would produce the following lines;
         counters are 1 and 6
         counters are 1 and 7
         counters are 1 and 8
         counters are 1 and 9
         counters are 5 and 5
         counters are 5 and 6
         counters are 5 and 7
         counters are 5 and 8
         counters are 5 and 9

    So this operation spec is line <counter number starting from 0> <operation>
    <number or characters>. Following operations are recognized: '+' add, '-'
    substract, '*' multiply, '.' and '~' for string concatenate.

    String concatenate is less obvious so an example here;
         a..c 0.x 'string %s %s'

    would produce the following lines;
         string a ax
         string a by
         string a cz
         string b ax
         string b by
         string b cz
         string c ax
         string c by
         string c cz

  Plugins:
    Genpath::Plugin::Echo. This plugin sends the texts to the /usr/bin/echo
      program. This is a good way to see what is generated and how many lines.
      This plugin is used by default.

    Genpath::Plugin::Wget. Send texts to the wget program.

  Config file:
    The config file is taken from files ./genpath.cfg, ./.genpath.cfg or
    ~/.genpath.cfg. The content is in TOML format. A sample config;

        [Genpath]

        [Genpath.Plugin]

        [Wget]
          workdir = '/home/johndoe/Download'

        [options.Wget]
           --timeout=120
           --wait=1
           --no-verbose

        # Wget options for plugin Genpath::Plugin::Wget
        [options.Wget.default]

        [Echo]

        [options.Echo]

        # Echo options for plugin Genpath::Plugin::Echo
        [options.Echo.default]
          -e=true

        # For use with -o=version
        [options.Echo.version]
          --version=true

        # For use with -o=help
        [options.Echo.help]
          --help=true

    - There are tables to control the Package and therefore the program. These
      are called, [Genpath], [Genpath.Plugin] and for each of the plugins like
      [Wget] and [Echo].
    - The package knows the following controls
        workdir = 'path/to/dir'
    - Empty sections are not obligated to write down. These can be of later use
      when program evolves.
    - Plugins use options which are set in the table [options.<plugin identity>]
    - The programs option -o=<section> can modify the plugins options. Create
      the table [options.<plugin identity>.<section>] to do that. The section
      'default' is used by default. The options found in that table are added to
      the list of options or, when the same options are used, overwrites them.
    - Boolean options are used to have options without values when true or when
      false to cancel them out.

  EOHELP
}
