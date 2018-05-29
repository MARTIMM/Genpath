use v6;
use Genpath::Plugin;
use Genpath::Options;

#-------------------------------------------------------------------------------
class Genpath:auth<github:MARTIM> {

  has Str $.sprintf-text = '';
  has Array $.ranges = [];
  has Array $.range-lists = [];
  has Array $.range-idxs = [];
  has Array $.range-locks = [];
  has Array $.counter-mappings = [];
  has Bool $.end-of-count;
  has Bool $.ignore-errors is rw = False;
  has Str $!option-section;
  has Bool $!once = False;

  has Genpath::Plugin $!plugin-hook;# handles <install-plugin>;
  has Genpath::Plugin $!plugin-object;

  # Regular expressions
  # something like: number,number+ ... number
  my regex if-number { <[-+]>? <digit>+ ( '.' <digit>+ ) ? };
  my regex dot3list { <if-number> ( ',' <if-number> )+ }
  my regex dot3range { <dot3list> '...' <final3number=if-number> }

  # A list of items
  my regex dot2spec1 { <if-number> '..'  <if-number> };
  my regex dot2spec2 { <alnum>+ '..'  <alnum>+ };
  my regex dot2list-item { <dot2spec1> | <dot2spec2> | <if-number> | <alnum>+ };
  my regex dot2list { <dot2list-item> ( ',' <dot2list-item> )* };

  #-----------------------------------------------------------------------------
  submethod BUILD (

    Str :$text = '', Array :$!ranges = [],
    Str :$plugin-module is copy = 'Echo', Str :$plugin-path,
    Genpath::Plugin :$object, Str :$!option-section = 'default'
  ) {

    $!sprintf-text = $text;
    $!end-of-count = False;
    $!counter-mappings = [^ $!ranges.elems];
    self!initialize-range-lists;
    self!initialize-range-references;

    $!plugin-hook = Genpath::Plugin.new unless $!plugin-hook.defined;

    # See if caller gives an object of its own
    if $object.defined and $object.^name ~~ m/^ 'Genpath::Plugin::' / {
      $!plugin-object = $object;
    }

    else {
      $plugin-module = 'Genpath::Plugin::Echo' if $plugin-module eq 'Echo';
      $plugin-module = 'Genpath::Plugin::Wget' if $plugin-module eq 'Wget';

      $!plugin-object = $!plugin-hook.install-plugin(
        $plugin-module, :$plugin-path
      );
#note "PO 0: $!plugin-object.^name()";
#note "PO 1: $!plugin-object.perl()";
    }
  }

#`{{
  #-----------------------------------------------------------------------------
  method install-plugin ( |c ) {

    $!plugin-object = $!plugin-hook.install-plugin(|c);
#note "G IP: $!plugin-object.^name()";
#$!plugin-object;
  }
}}

  #-----------------------------------------------------------------------------
  method !initialize-range-lists ( ) {

    if $!ranges.elems == 0 {
      $!once = True;
      return;
    }

note "RL: $!range-lists[*]";
    loop ( my $range-i = 0; $range-i < $!ranges.elems; $range-i++) {
note "Loop 1: $range-i";

      my $current-range-list := $!range-lists[$range-i];
      $current-range-list = [];

      my $current-range := $!ranges[$range-i];

      if $current-range ~~ m/^ <dot3range> $/ {

        my List $dot3start = |map {.Rat}, $<dot3range><dot3list>.Str.split(',').List;
        my $dot3end = $<dot3range><final3number>.Rat;

        $current-range-list.push(|[@$dot3start ... $dot3end]);
      }

      # Test for counter and offset n+m, n-m or n*m. These ranges are locked
      # with the referred counter.
      elsif $current-range ~~ m/^ $<counter>=\d+ $<oper>=<[\+\-\*\.\~]>
                                  $<offset>=[<if-number> | <alnum>+]
                                $/ {
        my $counter = ~$/<counter>;
        my $oper = ~$/<oper>;
        my $offset = ~$/<offset>;

        if $counter.defined and $oper.defined
           and $offset.defined and $counter < $range-i {

          my $range-ref = $!range-lists[$counter];
          my $cmin = $range-ref[0];
          my $cmax = $range-ref[$range-ref.end];
          if $oper eq '+' {
            $cmin += $offset.Int;
            $cmax += $offset.Int;
            $current-range-list.push(|[$cmin .. $cmax]);
          }

          elsif $oper eq '-' {
            $cmin -= $offset.Int;
            $cmax -= $offset.Int;
            $current-range-list.push(|[$cmin .. $cmax]);
          }

          elsif $oper eq '*' {
            $current-range-list.push(|[ map {$_ * $offset.Int}, @$range-ref]);
          }

          # This is not a calculation of offset but a string manipulation
          elsif $oper ~~ m/<[\.\~]>/ {
            my $off = $offset.Str;
            $current-range-list.push( |[
                map {
                  my $s = $_ ~ $off;
                  $off = $off.succ;
                  $s;
                },
                @$range-ref
              ]
            );
          }

          $!range-idxs[$range-i] = $counter;
        }

        else {
          say "Count, operator or offset not defined";
        }
      }

      # Test for digital and alphabetic ranges n..m and lists a,b
      elsif $current-range ~~ m/^ <dot2list> $/ {

        # Split on comma's and process resulting list
        my List $range-items = $current-range.split(',').List;
        for @$range-items -> $ri {

          # See if it is a range
          if $ri ~~ m/ \.\. / {
            ( my $rmin, my $rmax) = $ri.split('..').List;
            if $rmin ~~ m/^ <alpha>+ $/ or $rmax ~~ m/^ <alpha>+ $/ {
              $current-range-list.push(|[$rmin .. $rmax]);
            }

            elsif $rmin ~~ m/^ <digit>+ $/ and $rmax ~~ m/^ <digit>+ $/ {
              $current-range-list.push(|[$rmin.Int .. $rmax.Int]);
            }

            elsif $rmin ~~ m/^ <if-number> $/
               and $rmax ~~ m/^ <if-number> $/ {
              $current-range-list.push(|[$rmin.Rat .. $rmax.Rat]);
            }

            else {
              $current-range-list.push(|[$rmin .. $rmax]);
            }
          }

          elsif $ri ~~ m/^ <[-+]>? <digit>+ $/ {
            $current-range-list.push($ri.Int);
          }

          elsif $ri ~~ m/^ <if-number> $/ {
            $current-range-list.push($ri.Rat);
          }

          else {
            $current-range-list.push($ri);
          }
        }
      }
    }
  }

  #-----------------------------------------------------------------------------
  # Initialize range references. These are the indexes of the range lists and
  # thus set to 0.
  method !initialize-range-references ( ) {

    return unless ? $!range-lists;

    loop ( my $counter-i = 0; $counter-i < $!range-lists.elems; $counter-i++) {
note "Loop 2: $counter-i";
      my $ci = $!counter-mappings[$counter-i];
      $!range-idxs[$ci] = 0;
    }
  }

  #-----------------------------------------------------------------------------
  method get-args ( --> Array ) {

    return $!plugin-object.run-args;
  }

  #-----------------------------------------------------------------------------
  method redirect-texts ( ) {

    $!plugin-object.run-init(:$!option-section);

    if $!once {
      $!plugin-object.run($!sprintf-text);
    }

    else {
      while not $!end-of-count {

        # Generate the text
        my $generated-text = self.generate-text;

        # Send the text to the plugin to process it. Plugin return status.
        my Bool $no-error = $!plugin-object.run($generated-text);

        # Skip rest of last counter when there errors unless we must ignore it.
        self.skip-count unless $!ignore-errors or $no-error;

        # Next entry
        self.increment-count;
      }
    }

    $!plugin-object.run-finish;
  }

  #-----------------------------------------------------------------------------
  method generate-text ( --> Str ) {

    my @counters;
    my $text = $!sprintf-text;

    loop ( my $counter-i = 0; $counter-i < $!range-lists.elems; $counter-i++) {
      my $ci = $!counter-mappings[$counter-i];
      my $ri = $!range-idxs[$ci];
      push @counters, $!range-lists[$ci][$ri];
    }

    sprintf( "'$text'", @counters)
  }

  #-----------------------------------------------------------------------------
  method increment-count ( ) {

    # Increment last counter first
    loop ( my $counter-i = $!range-lists.end; $counter-i >= 0; $counter-i--) {

      # Get mapped counter
      my $ci = $!counter-mappings[$counter-i];

      # Get ref index.
      my $ri = $!range-idxs[$ci];

      # Check if counter is locked to another. If so skip
      if $!range-locks[$ci].defined {
        say "Counter $ci Locked to ", $!range-locks[$ci];
      }

      else {
        # Get length of range
        my $rlng = $!range-lists[$ci].end;

        # Increment if less than range length and stop.
        if $ri < $rlng {

          $!range-idxs[$ci] = $ri + 1;

          # Increment all counters depending on this one too. Dependency is on
          # previous counters so start with this counter + 1
          loop (
            my $dc_i = $counter-i+1;
            $dc_i < $!range-lists.elems;
            $dc_i++
          ) {

            my $dci = $!counter-mappings[$dc_i];
            my $dri = $!range-idxs[$dci];
            my $dcl = $!range-locks[$dci];
            if defined $dcl and $dcl == $ci {
              $!range-idxs[$dci] = $dri + 1;
            }
          }

          last;
        }

        # If $ri >= $rlng (== range length), set ref to 0 and check next
        # counter.
        else {

          $!range-idxs[$ci] = 0;

          # Reset all counters depending on this one too. Dependency is on
          # previous counters so start with this counter + 1
          loop (
            my $dc_i = $counter-i + 1;
            $dc_i < $!range-lists.elems;
            $dc_i++
          ) {

            my $dci = $!counter-mappings[$dc_i];
            my $dcl = $!range-locks[$dci];
            if $dcl.defined and $dcl == $ci {
              $!range-idxs[$dci] = 0;
            }
          }
        }
      }

      # While counting backwards the last counter is 0. Control will pass here
      # only when counters are reset for the next round or when a counter
      # depends on another counter.
      $!end-of-count = True unless $counter-i;
    }
  }

  #-----------------------------------------------------------------------------
  # Skip the rest of the last counter by resetting it to zero and incrementing
  # the lower counter by one.
  method skip-count ( ) {

    my $ci;
    my $ri;

    my $counter-i = $!range-lists.elems;
    ( $counter-i, $ci, $ri) = self!skip-locked-counters($counter-i);

    # Whatever the situation is for this counter, reset it.
    $!range-idxs[$ci] = 0;

    # Reset all counters depending on this one too. Dependency is on
    # previous counters so start with this counter + 1
    loop (
      my $dc_i = $counter-i + 1;
      $dc_i < $!range-lists.elems;
      $dc_i++
    ) {

      my $dci = $!counter-mappings[$dc_i];
      my $dcl = $!range-locks[$dci];
      if $dcl.defined and $dcl == $ci {
        $!range-idxs[$dci] = 0;
      }
    }

    my Bool $not-incremented = True;
    my $not-finished = True;
    while $not-incremented and $not-finished {

      # While counting backwards the last counter is 0. Control will pass here
      # only when counters are reset for the next round or when a counter
      # depends on another counter.
      if $counter-i <= 0 {
        $!end-of-count = True;
        $not-finished = False;
        last;
      }

      # Increment the next lower not locked counter
      ( $counter-i, $ci, $ri) = self!skip-locked-counters($counter-i);

      # Get length of range
      my $rlng = $!range-lists[$ci].elems;

      # Increment if less than range length and stop.
      # If not set ref to 0 and check next counter.
      if $ri < $rlng - 1 {

        $!range-idxs[$ci] = $ri + 1;

        # Increment all counters depending on this one too. Dependency is on
        # previous counters so start with this counter + 1        #
        loop (
          my $dc_i = $counter-i + 1;
          $dc_i < $!range-lists.elems;
          $dc_i++
        ) {

          my $dci = $!counter-mappings[$dc_i];
          my $dri = $!range-idxs[$dci];
          my $dcl = $!range-locks[$dci];
          if $dcl.defined and $dcl == $ci {
            $!range-idxs[$dci] = $dri + 1;
          }
        }

        $not-incremented = False;
      }

      else {

        $!range-idxs[$ci] = 0;

        # Reset all counters depending on this one too. Dependency is on
        # previous counters so start with this counter + 1
        loop (
          my $dc_i = $counter-i + 1;
          $dc_i < $!range-lists.elems;
          $dc_i++
        ) {

          my $dci = $!counter-mappings[$dc_i];
          my $dri = $!range-idxs[$dci];
          my $dcl = $!range-locks[$dci];
          if $dcl.defined and $dcl == $ci {
            $!range-idxs[$dci] = 0;
          }
        }
      }
    }
  }

  #-----------------------------------------------------------------------------
  # Skip locked counters
  method !skip-locked-counters ( Int $counter-i is copy ) {

    my $ci;
    my $ri;

    # Check if counter is locked to another. If so skip.
    repeat {

      $counter-i--;

      $ci = $!counter-mappings[$counter-i];             # mapped counter
      $ri = $!range-idxs[$ci];                          # ref index
    } while $!range-locks[$ci].defined and $counter-i > 0;

    return ( $counter-i, $ci, $ri);
  }
}
