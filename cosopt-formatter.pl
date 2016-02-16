#!/usr/bin/env perl
# Mike Covington
# created: 2015-08-24
#
# Description: Convert expression data into COSOPT input files
#
use strict;
use warnings;
use autodie;
use feature 'say';
use File::Path 'make_path';
use Getopt::Long;
use List::MoreUtils 'zip';
use List::Util 'sum';

my $outdir = 'Session';

my $period_min = 20;
my $period_max = 28;
my $period_inc = 0.1;

my $options = GetOptions (
    "outdir=s"     => \$outdir,
    "period_min=i" => \$period_min,
    "period_max=i" => \$period_max,
    "period_inc=f" => \$period_inc,
);

my @file_list = @ARGV;

my $data_dir = join "/", $outdir, "data";
make_path $data_dir;
make_path join "/", $outdir, "opt";

my $period_limits = {
    'min'       => "$period_min.",
    'max'       => "$period_max.",
    'increment' => $period_inc,
};

my $expression_data = {};

for my $file (@file_list) {
    get_expression_data($file, $expression_data);
}

process_data($expression_data);

write_cosopt_input($expression_data, $period_limits);



sub get_expression_data {
    my ( $expression_file, $expression_data ) = @_;

    open my $expression_fh, "<", $expression_file;

    my ( $gene_header, @timepoints ) = split "\t", <$expression_fh>;
    chomp @timepoints;

    while (<$expression_fh>) {
        chomp;
        my ( $gene_id, @counts ) = split;
        for my $i ( 0..$#timepoints ) {
            push @{$$expression_data{$gene_id}{$timepoints[$i]}}, $counts[$i];
        }
    }
    close $expression_fh;
}

sub process_data {
    my $expression_data = shift;

    for my $gene_id ( keys %$expression_data ) {
        for my $timepoint ( keys %{$$expression_data{$gene_id}} ) {
            my ( $mean, $sem ) = calc_mean_and_se(@{$$expression_data{$gene_id}{$timepoint}});
            $$expression_data{$gene_id}{$timepoint} = {
                'mean' => $mean,
                'sem'  => $sem,
            }
        }
    }
}

sub calc_mean_and_se {
    my @data = @_;

    my $count = scalar @data;
    my $mean = sum(@data) / $count;

    my $std_dev_sum = 0;
    $std_dev_sum += ( $_ - $mean ) ** 2 for @data;
    my $std_dev = $count > 1 ? sqrt( $std_dev_sum / ( $count - 1 ) ) : 0;
    my $sem = $std_dev / sqrt( $count );

    return $mean, $sem;
}

sub write_cosopt_input {
    my ( $expression_data, $period_limits ) = @_;

    my $gene_count = 0;
    my $period_min = $$period_limits{'min'};
    my $period_max = $$period_limits{'max'};
    my $period_inc = $$period_limits{'increment'};

    open my $gene_id_fh, ">", join( "/", $outdir, "GeneID.DAT" );
    open my $cosopt_L_fh, ">", join( "/", $outdir, "cosoptL.in" );
    open my $cosopt_2L_fh, ">", join( "/", $outdir, "cosopt2L.in" );
    open my $cosopt_3_fh, ">", join( "/", $outdir, "cosopt3.in" );
    open my $cosopt_4_fh, ">", join( "/", $outdir, "cosopt4.in" );
    open my $bat_fh, ">", join( "/", $outdir, "doit.bat" );

    say $cosopt_L_fh join( ",", $period_min, $period_max, $period_inc );
    say $cosopt_L_fh "n";

    say $cosopt_2L_fh "session.op2";

    say $cosopt_3_fh join( "\n", "session.op2", "session.op3", "GeneID.DAT",
        "$period_min,$period_max", "2.", "y", "n" );

    say $cosopt_4_fh join( "\n", "session.op3", "session.op4" );

    say $bat_fh <<'EOF';
..\programs\cosoptL.new < cosoptL.in
..\programs\cosopt2L.new < cosopt2L.in
..\programs\cosopt3.new < cosopt3.in
..\programs\cosopt4.new < cosopt4.in
EOF

    close $cosopt_3_fh;
    close $cosopt_4_fh;
    close $bat_fh;

    for my $gene_id ( sort { "\L$a" cmp "\L$b" } keys %$expression_data ) {
        $gene_count++;

        my $gene_count_padded = sprintf( "%08d", $gene_count );
        say $gene_id_fh "File $gene_count_padded=$gene_id";

        say $cosopt_L_fh "data\\$gene_count_padded.DAT";
        say $cosopt_L_fh "opt\\$gene_count_padded.OPT";

        say $cosopt_2L_fh "opt\\$gene_count_padded.OPT";

        open my $dat_fh, ">", join( "/", $data_dir, "$gene_count_padded.DAT" );
        for my $timepoint ( sort { $a <=> $b } keys %{$$expression_data{$gene_id}} ) {
            my $mean = $$expression_data{$gene_id}{$timepoint}{'mean'};
            my $sem = $$expression_data{$gene_id}{$timepoint}{'sem'};
            say $dat_fh join(",", $mean, $sem, $timepoint);
        }
        close $dat_fh;
    }
    close $gene_id_fh;
    close $cosopt_L_fh;
    close $cosopt_2L_fh;
}
