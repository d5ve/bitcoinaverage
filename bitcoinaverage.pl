#!/usr/bin/perl

use strict;
use warnings;
use v5.10;

=head1 NAME

bitcoinaverage.pl - fetch bitcoin pricing info from api.bitcoinaverage.com

=head1 SYNOPSIS

    Fetch bitcoin pricing info from api.bitcoinaverage.com    
    Prints current 24-hour average, previous 7 days average, 14th, 21st, and 28th previous day average. 

    bitcoinaverage.pl [options]

    Options:
        --primary_currency=     Defaults to USD.
        --local_currency=       Defaults to NZD.

=cut

use Getopt::Long;
use HTTP::Tiny;
use JSON;
use Pod::Usage;

my $ticker_url          = q{https://api.bitcoinaverage.com/ticker/all};
my $history_url_format  = q{https://api.bitcoinaverage.com/history/%s/per_day_all_time_history.csv};
my $primary_currency    = 'USD';
my $local_currency      = 'NZD';
my $ticker_output_field = '24h_avg';

GetOptions(
    'primary_currency=s' => \$primary_currency,
    'local_currency=s'   => \$local_currency,
    'help|?'             => sub { pod2usage() },
) or pod2usage();

my $ticker_response = HTTP::Tiny->new->get($ticker_url);
if ( !$ticker_response->{success} ) {
    say "Unable to GET '$ticker_url': $ticker_response->{status} $ticker_response->{reason}";
    exit;
}
my $ticker_data = JSON::decode_json( $ticker_response->{content} );

say "$primary_currency: $ticker_data->{$primary_currency}->{$ticker_output_field}";
my @history = get_historical_data($primary_currency, $history_url_format);
say "           " . join(' ', @history);
if ( $primary_currency ne $local_currency ) {
    say "$local_currency: $ticker_data->{$local_currency}->{$ticker_output_field}" if $primary_currency ne $local_currency;
    my @history = get_historical_data($local_currency, $history_url_format);
    say "           " . join(' ', @history);
}

exit;

#
# Currently print last 7 days, then previous 3 weeks.
#
sub get_historical_data {
    my $currency = shift;
    my $history_url_format = shift;

    my $history_response = HTTP::Tiny->new->get(sprintf $history_url_format, $currency);
    if ( !$history_response->{success} ) {
        say "Unable to GET '" . sprintf($history_url_format, $currency) . "': $history_response->{status} $history_response->{reason}";
        exit;
    }

    my @history = ('7day');
    my @days = reverse split(m{\n}, $history_response->{content});
    my $counter = 0;
    for ( @days ) {
        my ($datetime, $high, $low, $average, $volume) = split m{,}, $_;
        $average =~ s{\..*}{}xms;
        push @history, $average if $counter < 7;
        push @history, "3week", $average if $counter == 13;
        push @history, $average if $counter == 20;
        push @history, $average if $counter == 27;
        last if $counter == 27;
        $counter ++;
    }

    return @history;
}

__END__

=head1 LICENSE

This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

=cut
