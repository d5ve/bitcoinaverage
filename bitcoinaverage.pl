#!/usr/bin/perl

use strict;
use warnings;
use v5.10;

=head1 NAME

bitcoinaverage.pl - fetch bitcoin pricing info from api.bitcoinaverage.com

=cut

use HTTP::Tiny;
use JSON;

my $ticker_url       = q{https://api.bitcoinaverage.com/ticker/all};
my $primary_currency = 'USD';
my $local_currency   = 'NZD';
my $output_field     = '24h_avg';

my $response = HTTP::Tiny->new->get($ticker_url);

if ( !$response->{success} ) {
    say "Unable to GET '$ticker_url': $response->{status} $response->{reason}";
    exit;
}

my $data = JSON::decode_json( $response->{content} );

say "$primary_currency: $data->{$primary_currency}->{$output_field}";
say "$local_currency: $data->{$local_currency}->{$output_field}" if $primary_currency ne $local_currency;

exit;

__END__

=head1 LICENSE

This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

=cut
