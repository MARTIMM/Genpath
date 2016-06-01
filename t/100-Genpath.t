use v6.c;
use Test;
use Genpath;

#-------------------------------------------------------------------------------
  spurt( 'genpath.cfg', Q:to/EOOPT/);
  [Genpath]
    workdir = '.'

  [Genpath.Plugin]
    workdir = '.'


  # Wget plugin
  [Wget]
    workdir = '.'

  [options.Wget]
    --force-directories=true
    --timeout=120
    --wait=1

  # Wget options for plugin Genpath::Plugin::Wget
  [options.Wget.default]
    --no-verbose=true


  # Echo plugin
  [Echo]
    workdir = '/tmp'

  # Echo options for plugin Genpath::Plugin::Echo
  [options.Echo]
    -e=true

  # For use with -o=version
  [options.Echo.version]
    --version=true

  # For use with -o=help
  [options.Echo.help]
    --help=true
  EOOPT

#-------------------------------------------------------------------------------
subtest {

  my Genpath $g .= new(:ranges(['1..5']));
  is-deeply $g.counter-mappings, [0], '1 counter map';
  is-deeply $g.range-lists, [[1,2,3,4,5],], "result: $g.range-lists.perl()";

  $g .= new(:ranges([ '1..5', '0+2']));
  is-deeply $g.counter-mappings, [ 0, 1], '2 counter maps';
  is-deeply $g.range-lists, [ [1,2,3,4,5], [3,4,5,6,7]],
            "result: $g.range-lists.perl()";

  $g .= new(:ranges([ '11..14', '0-3']));
  is-deeply $g.range-lists, [ [11,12,13,14], [8,9,10,11]],
            "result: $g.range-lists.perl()";

  $g .= new(:ranges([ '0,2..3,6', '0*3']));
  is-deeply $g.range-lists, [ [0,2,3,6], [0,6,9,18]],
            "result: $g.range-lists.perl()";

  $g .= new(:ranges(['ah..al']));
  is-deeply $g.range-lists, [[<ah ai aj ak al>],],
            "result: $g.range-lists.perl()";

  $g .= new(:ranges([ 'ah..al', '0.x']));
  is-deeply $g.range-lists, [ [<ah ai aj ak al>], [<ahx aiy ajz akaa alab>]],
            "result: $g.range-lists.perl()";

  $g .= new(:ranges([ 'x,ah..ai', '0.x']));
  is-deeply $g.range-lists, [ [<x ah ai>], [<xx ahy aiz>]],
            "result: $g.range-lists.perl()";

  $g .= new(:ranges([ '4.1,5...7.7']));
  is-deeply $g.range-lists, [ [4.1,5.0,5.9,6.8,7.7],],
            "result: $g.range-lists.perl()";

  $g .= new(:ranges([ '1..5', '0+4', '3..6']));
  is-deeply $g.range-idxs, [ 0, 0, 0], 'check range indexes';

}, 'initialize';

#-------------------------------------------------------------------------------
subtest {

  my Genpath $g .= new(
    :text('%d %d %d'),
    :ranges([ '1..5', '0+4', '3..6'])
  );
  my $gt = $g.generate-text;
  is $gt, "'1 5 3'", "generated text $gt";

  $g.increment-count;
  $gt = $g.generate-text;
  is $gt, "'1 5 4'", "generated text $gt";

  for ^3 {$g.increment-count;}
  $gt = $g.generate-text;
  is $gt, "'1 6 3'", "generated text $gt";

  while not $g.end-of-count {
    $g.increment-count;
    last if $g.range-idxs eqv [ 4, 4, 3];
  }

  $gt = $g.generate-text;
  is $gt, "'5 9 6'", "generated text $gt";

  $g .= new(
    :text('%s %02d 0x%02x'),
    :ranges([ 'a..c', '3..6', '1*2'])
  );
  $gt = $g.generate-text;
  is $gt, "'a 03 0x06'", "generated text $gt";
  $g.skip-count;
  $g.increment-count;
  $g.increment-count;
  $gt = $g.generate-text;
  is $gt, "'a 04 0x0a'", "generated text $gt";
  $g.skip-count;
  $gt = $g.generate-text;
  is $gt, "'a 05 0x06'", "generated text $gt";
  $g.increment-count;
  $g.increment-count;
  $g.increment-count;
  $gt = $g.generate-text;
  is $gt, "'a 05 0x0c'", "generated text $gt";

}, 'generate';

#-------------------------------------------------------------------------------
subtest {

  my Genpath $g .= new( :text('%1.1f'), :ranges([ '1..5',]));

  $g.install-plugin('Genpath::Plugin::Echo');
  my $echo = $g.generate-object('Genpath::Plugin::Echo');
  is $echo.^name, 'Genpath::Plugin::Echo', 'Echo plugin';

# We let the Echo have a workdir in /tmp so we cannot test these line anymore
#  $echo.run-init(:option-section<default>);
#  is $echo.command-path, '/usr/bin/echo', "command path: $echo.command-path()";

  $g.redirect-texts;
  

}, 'object';

#-------------------------------------------------------------------------------
subtest {

  mkdir "t/P";
  spurt "t/P/MyEcho.pm6", Q:to/EOPLUGIN/;
    use v6.c;
    use Genpath::Plugin;
    use Test;
    class t::P::MyEcho is Genpath::Plugin {
    #class P::MyEcho is Genpath::Plugin {

      #-----------------------------------------------------------------------------
      method identity ( --> Str ) {
        'MyEcho';
      }

      #-----------------------------------------------------------------------------
      method command ( --> Str ) {
        '/usr/bin/echo';
      }

      #-----------------------------------------------------------------------------
      method run-execute ( Str:D $command-line --> Bool ) {

        state Int $run-count = 0;
        #say $command-line;
        ok( $command-line ~~ m/'-2 2 -3'/, $command-line) if $run-count == 0;
        ok( $command-line ~~ m/'-2 4 -3'/, $command-line) if $run-count == 4;
        ok( $command-line ~~ m/'0 2 -3'/, $command-line)  if $run-count == 12;
        $run-count++;
        return True;
      }
    }

    EOPLUGIN

  #use lib 't';
  my Genpath $g .= new(
    :text('%d %d %d'),
    :ranges([ '-2..0', '0+4', '-3..-2']),
    :plugin-module<t::P::MyEcho>,
    #:plugin-path<t>
  );

  $g.redirect-texts;

  unlink "t/P/MyEcho.pm6";
  rmdir "t/P";

}, 'plugin P::MyEcho';

#-------------------------------------------------------------------------------
subtest {

  my Genpath $g .= new(
    :text('http://automake.co.uk/a/img/gallery/jewellery/thumbs/%03d.jpg'),
    :ranges([ '1,2']),
    :plugin-module<Genpath::Plugin::Wget>,
    :run-args([< -x --ignore-length --page-requisites --no-clobber
               --continue --timeout=120 --wait=1 -q
             >])
  );

  $g.redirect-texts;

  ok 'automake.co.uk/a/img/gallery/jewellery/thumbs/001.jpg'.IO:e, 'thumb 001.jpg';
  ok 'automake.co.uk/a/img/gallery/jewellery/thumbs/001.jpg'.IO:e, 'thumb 002.jpg';

  unlink 'automake.co.uk/a/img/gallery/jewellery/thumbs/001.jpg';
  unlink 'automake.co.uk/a/img/gallery/jewellery/thumbs/002.jpg';
  rmdir 'automake.co.uk/a/img/gallery/jewellery/thumbs';
  rmdir 'automake.co.uk/a/img/gallery/jewellery';
  rmdir 'automake.co.uk/a/img/gallery';
  rmdir 'automake.co.uk/a/img';
  rmdir 'automake.co.uk/a';
  rmdir 'automake.co.uk';

}, 'plugin Wget';

#-------------------------------------------------------------------------------
# Cleanup
#
unlink 'genpath.cfg';
done-testing();
exit(0);
