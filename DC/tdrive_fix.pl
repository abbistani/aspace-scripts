#!/usr/bin/env perl
#
use strict;
use warnings;
use LWP::UserAgent;
use JSON;
use Data::Dumper;

my $token = '01e5623e96a2f5f9c29831623077e07f9892483945f951adeeecd153d7753cef';
my $ua = LWP::UserAgent->new;

  my $resource_uri;
  my $resource;
  my $resource_json;
  my @working_list;
  my $server = 'https://alh.archives.dcl.org/staff/api';
  
  my $listline = $server . '/repositories/2/accessions?all_ids=true';
  my $listrequest = HTTP::Request->new(GET => $listline);
  $listrequest->header('X-ArchivesSpace-Session' => $token);
  my $list_response = $ua->request($listrequest);

  if ($list_response->is_success) {
    print $list_response->decoded_content, "\n";
    my $idlist = $list_response->decoded_content;
    $idlist =~ s/[\[\]]//g;
    @working_list = split /,/, $idlist;
  } else {
    print $list_response->status_line, "\n";
    print "On $listline\n";
  }

  #@working_list = qw/ 5 /;

foreach my $id (@working_list) {  
  my $note_deleted = 0;
  my $resourceline = $server . '/repositories/2/accessions/' . $id;
  print "processing $resourceline\n";
  my $resource_request =  HTTP::Request->new(GET => $resourceline);
  $resource_request->header('X-ArchivesSpace-Session' => $token);
  my $resource_response = $ua->request($resource_request);
  if ($resource_response->is_success) {
    $resource = decode_json($resource_response->decoded_content);
    #print Dumper($resource) . "\n";
    my $index = 0;
    foreach my $note (@{$resource->{external_documents}}) {
      if ($note->{location} eq 'Tdrive')  {
        splice (@{$resource->{external_documents}},$index,1);
        print "\tdeleted Tdrive from $id\n";
        $note_deleted = 1;
      }
      $index++;
    }
    #print Dumper(@{$resource->{notes}}) . "\n";
    $resource_json = encode_json($resource);
    #print $resource_json . "\n";
  } else {
    print $resource_response->status_line, "\n";
    print "On $resourceline\n";
  }

  if ($note_deleted) {
    my $resource_post =  HTTP::Request->new(POST => $resourceline);
    $resource_post->header('X-ArchivesSpace-Session' => $token);
    $resource_post->content_type('application/json');
    $resource_post->content($resource_json);
    #print $resource_json . "\n";

    my $post_response = $ua->request($resource_post);

    if ($post_response->is_success) {
      print $post_response->decoded_content, "\n";
    } else {
      print $post_response->status_line, "\n";
    }
  }
}
