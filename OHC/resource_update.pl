#!/usr/bin/env perl
#
use strict;
use warnings;
use LWP::UserAgent;
use Data::Dumper;
use JSON;
use URI::Encode;
use Text::CSV_XS;

my $token = '5e8e9f0e1ed5b6a9786c0a858f74b69c9d9faf17ce5cb0b8d62fc87a1663b7aa';
my $server='https://aspace.ohiohistory.org/staff/api';
my $component_id = 'BV 03215';
my $resource_uri;
my $ao;
my $resource_json;
my @rows;
my $csv = Text::CSV_XS->new ( { binary => 1, allow_whitespace => 1 } )  # should set binary attribute.
               or die "Cannot use CSV: ".Text::CSV_XS->error_diag ();

my $encoder = URI::Encode->new();
my $ua = LWP::UserAgent->new;

open my $fh, "<:encoding(utf8)", "vfm-scope.csv" or die "bv-updates.csv";
my @cols = @{$csv->getline ($fh)};
$csv->column_names (@cols);

while (my $row = $csv->getline_hr($fh)) {
  my $component_id = $row->{resource_id};

  my $searchline = $server . '/repositories/2/find_by_id/resources?identifier[]=["' . $component_id . '"]';
  $searchline = $encoder->encode($searchline);
  print $searchline . "\n";
  my $request = HTTP::Request->new(GET => $searchline);
  $request->header('X-ArchivesSpace-Session' => $token);

  my $search_response = $ua->request($request);

  if ($search_response->is_success) {
    print $search_response->decoded_content, "\n";
    my $search_results = decode_json($search_response->decoded_content);
    $resource_uri = $search_results->{resources}[0]->{ref};
  } else {
    print $search_response->status_line, "\n";
    print $component_id, "failed\n";
    print "On $searchline\n";
  }

  my $resource_line = $server . $resource_uri;
  print $resource_line;
  my $resource_request = HTTP::Request->new(GET => $resource_line);
  $resource_request->header('X-ArchivesSpace-Session' => $token);
  my $resource_response = $ua->request($resource_request);
  if ($resource_response->is_success) {
    $ao = decode_json($resource_response->decoded_content);
    #print Dumper($ao) . "\n";
    my $note = { jsonmodel_type => "note_multipart",
                  type => "scopecontent",
                  publish => \1,
                  subnotes => [{ jsonmodel_type => "note_text",
                                  content => $row->{note_text},
                                  publish => \1
                                }]
                };
    push @{$ao->{notes}}, $note;
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

