#!/usr/bin/env perl
#
use strict;
use warnings;
use LWP::UserAgent;
use JSON;
use Data::Dumper;

my $token = 'e7663f95d7528e76fb7e2eaa24e07d513e9c5f70d2cd835f03738ef9adb2fbc6';
my $ua = LWP::UserAgent->new;

while (<>) {
  my $resource_uri;
  my $resource;
  my $resource_json;
  my ($resource_id, $class_uri) = split /,/;
  my $searchline = 'http://prettyboy.local:4567/repositories/2/find_by_id/resources?identifier[]=["' . $resource_id . '"]';
  my $request = HTTP::Request->new(GET => $searchline);
  $request->header('X-ArchivesSpace-Session' => $token);

  my $search_response = $ua->request($request);

  if ($search_response->is_success) {
    print $search_response->decoded_content, "\n";
    my $search_results = decode_json($search_response->decoded_content);
    $resource_uri = $search_results->{resources}[0]->{ref} . "\n";
  } else {
    print $search_response->status_line, "\n";
    print "On $searchline\n";
  }

  my $resourceline = 'http://prettyboy.local:4567' . $resource_uri;
  my $resource_request =  HTTP::Request->new(GET => $resourceline);
  $resource_request->header('X-ArchivesSpace-Session' => $token);
  my $resource_response = $ua->request($resource_request);
  if ($resource_response->is_success) {
    $resource = decode_json($resource_response->decoded_content);
    #print Dumper($resource) . "\n";
    $resource->{classifications}[0] = {ref => $class_uri};
    $resource_json = encode_json($resource);
    print $resource_json . "\n";
  } else {
    print $resource_response->status_line, "\n";
    print "On $resourceline\n";
  }

  my $resource_post =  HTTP::Request->new(POST => $resourceline);
  $resource_post->header('X-ArchivesSpace-Session' => $token);
  $resource_post->content_type('application/json');
  $resource_post->content($resource_json);
  print $resource_json . "\n";

  my $post_response = $ua->request($resource_post);

  if ($post_response->is_success) {
    print $post_response->decoded_content, "\n";
  } else {
    print $post_response->status_line, "\n";
  }

}
