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

my $options = GetOptions (
    "outdir=s" => \$outdir,
);

my @file_list = @ARGV;

my $data_dir = join "/", $outdir, "data";
make_path $data_dir;

my $expression_data = {};

for my $file (@file_list) {
    get_expression_data($file, $expression_data);
}

process_data($expression_data);

write_cosopt_input($expression_data);



sub get_expression_data {
    my ( $expression_file, $expression_data ) = @_;

    open my $expression_fh, "<", $expression_file;

    my ( $gene_header, @timepoints ) = split "\t", <$expression_fh>;
    chomp @timepoints;

    while (<$expression_fh>) {
        chomp;
        my ( $gene_id, @counts ) = split;
        for my $i ( 1..$#timepoints ) {
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
    my $expression_data = shift;

    my $gene_count = 0;

    open my $gene_id_fh, ">", join( "/", $data_dir, "GeneID.DAT" );

    for my $gene_id ( sort { "\L$a" cmp "\L$b" } keys %$expression_data ) {
        $gene_count++;

        my $gene_count_padded = sprintf( "%08d", $gene_count );
        say $gene_id_fh "File $gene_count_padded=$gene_id";

        open my $dat_fh, ">", join( "/", $data_dir, "$gene_count_padded.DAT" );
        for my $timepoint ( sort { $a <=> $b } keys %{$$expression_data{$gene_id}} ) {
            my $mean = $$expression_data{$gene_id}{$timepoint}{'mean'};
            my $sem = $$expression_data{$gene_id}{$timepoint}{'sem'};
            say $dat_fh join(",", $mean, $sem, $timepoint);
        }
        close $dat_fh;
    }
    close $gene_id_fh;
}
