#!/usr/bin/env perl
#
use strict;
use warnings;
use LWP::UserAgent;
use Data::Dumper;
use JSON;
use URI::Encode;
use Text::CSV_XS;

my $token = 'c5f17ffb35f6c7cc342836df8810084b7fdc5f2a3552c57ce82cf6d8b9d7c423';
my $server='https://aspace.ohiohistory.org/staff/api/';
my $component_id = 'BV 03215';
my $ao_uri;
my $ao;
my $ao_json;
my @rows;
my $csv = Text::CSV_XS->new ( { binary => 1, allow_whitespace => 1 } )  # should set binary attribute.
               or die "Cannot use CSV: ".Text::CSV_XS->error_diag ();

my $encoder = URI::Encode->new();
my $ua = LWP::UserAgent->new;

open my $fh, "<:encoding(utf8)", "bv-updates.csv" or die "bv-updates.csv";
my @cols = @{$csv->getline ($fh)};
$csv->column_names (@cols);

while (my $row = $csv->getline_hr($fh)) {
  my $component_id = $row->{resource_id};

  my $searchline = $server . 'repositories/2/find_by_id/archival_objects?component_id[]=' . $component_id;
  $searchline = $encoder->encode($searchline);
  print $searchline . "\n";
  my $request = HTTP::Request->new(GET => $searchline);
  $request->header('X-ArchivesSpace-Session' => $token);

  my $search_response = $ua->request($request);

  if ($search_response->is_success) {
    print $search_response->decoded_content, "\n";
    my $search_results = decode_json($search_response->decoded_content);
    $ao_uri = $search_results->{archival_objects}[0]->{ref} . "\n";
  } else {
    print $search_response->status_line, "\n";
    print $component_id, "failed\n";
    print "On $searchline\n";
  }

  my $ao_line = $server . $ao_uri;
  my $ao_request = HTTP::Request->new(GET => $ao_line);
  $ao_request->header('X-ArchivesSpace-Session' => $token);
  my $ao_response = $ua->request($ao_request);
  if ($ao_response->is_success) {
    $ao = decode_json($ao_response->decoded_content);
    #print Dumper($ao) . "\n";
    $ao->{title} = $row->{new_title};
    $ao_json = encode_json($ao) 
  } else {
    print $ao_response->status_line, "\n";
    print "On $ao_line\n";
  }

  my $ao_post = HTTP::Request->new(POST => $ao_line);
  $ao_post->header('X-ArchivesSpace-Session' => $token);
  $ao_post->content_type('application/json');
  $ao_post->content($ao_json);

  my $post_response = $ua->request($ao_post);

  if ($post_response->is_success) {
    print $post_response->decoded_content, "\n";
  } else {
    print $post_response->status_line, "\n";
  }

}

