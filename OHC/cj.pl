#!/usr/bin/env perl
#
use strict;
use warnings;
use LWP::UserAgent;

my $token = '4bdea0df82fc5228b7269f7009e2a34c63d8911b3e5975f93fee8d3c0da60b09';
my $ua = LWP::UserAgent->new;
while (<>) {
  my $request = HTTP::Request->new(POST => 'http://prettyboy.local:4567/repositories/2/classification_terms');
  $request->header('X-ArchivesSpace-Session' => $token);
  $request->content_type('application/json');
  $request->content($_);
  
  my $response = $ua->request($request);

  if ($response->is_success) {
    print $response->decoded_content, "\n";
  } else {
    print $response->status_line, "\n";
  }
  sleep 1;
}
