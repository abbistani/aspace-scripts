#!/usr/bin/env perl
#
use strict;
use warnings;
use LWP::UserAgent;
use Data::Dumper;
use JSON;
use URI::Encode;
use Text::CSV_XS;

my $token = 'f9cb97f76610e58c74ffaf892b5a460d753bf8013515bd4610bf909795449ae9';
my $server='https://cslarchives.ctstatelibrary.org/staff/api';
my $resource_uri;
my $ao;
my $resource_json;
my @rows;
my $csv = Text::CSV_XS->new ( { binary => 1, allow_whitespace => 1 } )  # should set binary attribute.
               or die "Cannot use CSV: ".Text::CSV_XS->error_diag ();

my $encoder = URI::Encode->new();
my $ua = LWP::UserAgent->new;

open my $fh, "<:encoding(utf8)", "ead_urls.csv" or die "can't open csv";
my @cols = @{$csv->getline ($fh)};
$csv->column_names (@cols);

while (my $row = $csv->getline_hr($fh)) {
  my $resource_line = $server . $row->{RESOURCE};
  print $resource_line;
  my $resource_request = HTTP::Request->new(GET => $resource_line);
  $resource_request->header('X-ArchivesSpace-Session' => $token);
  my $resource_response = $ua->request($resource_request);
  if ($resource_response->is_success) {
    $ao = decode_json($resource_response->decoded_content);
    #print Dumper($ao) . "\n";
    $ao->{ead_location} = $row->{URL};
    $resource_json = encode_json($ao) 
  } else {
    print $resource_response->status_line, "\n";
    print "On $resource_line\n";
  }

  my $resource_post = HTTP::Request->new(POST => $resource_line);
  $resource_post->header('X-ArchivesSpace-Session' => $token);
  $resource_post->content_type('application/json');
  $resource_post->content($resource_json);

  my $post_response = $ua->request($resource_post);

  if ($post_response->is_success) {
    print $post_response->decoded_content, "\n";
  } else {
    print $post_response->status_line, "\n";
    print $post_response->decoded_content, "\n";
  }

}

