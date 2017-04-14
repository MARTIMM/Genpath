use v6;
use lib '.';
use Test;
use Genpath;
use Genpath::Options;

#-------------------------------------------------------------------------------
spurt( 'genpath.cfg', Q:to/EOOPT/);
  [Genpath]

  [Genpath.Plugin]


  # Wget plugin
  [Wget]

  [options.Wget]
    --timeout=120
    --wait=1
    --force-directories=true
    -q=true

  # Wget options for plugin Genpath::Plugin::Wget
  [options.Wget.default]
    -q=false

  [options.Wget.quiet]
    -q=true
    --no-verbose=true

  [options.Wget.test3]
    --no-verbose=true
    --no-clobber=true
    --timeout=200


  # Echo plugin
  [Echo]

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

  my Genpath::Options $o .= new;
  my Array $options = $o.config-options( 'Wget', 'default');

  ok ('--force-directories' ~~ any @$options),
     'wget option --force-directories found';
  ok ('--wait=1' ~~ any @$options), 'wget option --wait is 1';


  $options = $o.config-options( 'Echo', 'version');
  ok ('--version' ~~ any @$options), 'echo option --version found';

}, "options";

#-------------------------------------------------------------------------------
subtest {

  my Genpath $g .= new(
    :text('http://automake.co.uk/a/img/gallery/jewellery/thumbs/%03d.jpg'),
    :ranges([ '1,2']),
    :plugin-module<Genpath::Plugin::Wget>,
    :option-section<quiet>
  );

  $g.redirect-texts;

  ok 'automake.co.uk/a/img/gallery/jewellery/thumbs/001.jpg'.IO:e, 'thumb 001.jpg';
  ok 'automake.co.uk/a/img/gallery/jewellery/thumbs/001.jpg'.IO:e, 'thumb 002.jpg';

  # Can only be tested after redirect-texts()
  my Array $args = $g.get-args;
  ok ('-q' ~~ any @$args), "wget arg '-q'";
  ok ('--force-directories' ~~ any @$args), "wget = '--force-directories'";
  ok ('--timeout=120' ~~ any @$args), "wget = '--timeout=120'";

}, 'plugin Wget';


#-------------------------------------------------------------------------------
subtest {

  my Genpath $g .= new(
    :text('http://automake.co.uk/a/img/gallery/jewellery/thumbs/%03d.jpg'),
    :ranges([ '1,2']),
    :plugin-module<Genpath::Plugin::Wget>,
    :option-section<test3>,
  );

  $g.redirect-texts;

  ok 'automake.co.uk/a/img/gallery/jewellery/thumbs/001.jpg'.IO:e, 'thumb 001.jpg';
  ok 'automake.co.uk/a/img/gallery/jewellery/thumbs/001.jpg'.IO:e, 'thumb 002.jpg';

  # Can only be tested after redirect-texts()
  my Array $args = $g.get-args;
  ok ('-q' ~~ any @$args), "wget arg 0 = '-q'";
  ok ('--no-clobber' ~~ any @$args), "wget arg '-nc' -> '--no-clobber'";
  ok ('--timeout=200' ~~ any @$args), "wget arg '--timeout=120' modified in 200";
  ok ('--force-directories' ~~ any @$args), "wget arg 0 = '--force-directories'";

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
