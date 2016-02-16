#!/usr/bin/env perl
# Mike Covington
# created: 2015-08-28
#
# Description: Convert COSOPT output into a more user-friendly format
#
use strict;
use warnings;
use autodie;
use feature 'say';

die <<USAGE unless scalar @ARGV == 2;
Usage:
  $0 <COSOPT RESULTS FILE> <REFORMATTED OUTPUT FILE>
USAGE

my ( $cosopt_file, $output_file ) = @ARGV;

open my $cosopt_fh, "<", $cosopt_file;
open my $output_fh, ">", $output_file;

# ORIGINAL COLUMN ORDER
# 0: File#
# 1: MeanExpLev
# 2: Period
# 3: Phase
# 4: Beta
# 5: pMMC-Beta
# 6: GeneID
my @order = ( 6, 1, 2, 3, 4, 5 );

say $output_fh join "\t", ( split /\s+/, <$cosopt_fh> )[@order];
<$cosopt_fh>;    # header underlines

while (<$cosopt_fh>) {
    s/^\s+//;
    say $output_fh join "\t", ( split /\s+/ )[@order];
}

close $cosopt_fh;
close $output_fh;
