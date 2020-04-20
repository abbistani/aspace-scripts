#!/usr/bin/env perl
#
use strict;
use warnings;
use LWP::UserAgent;
use JSON;
use Data::Dumper;



my $token = '2aebd520ad37198b6041feca04e0d7ae57b14b2f8d18499a697ca908588af56d';
my $ua = LWP::UserAgent->new;
my $res;
my $resource;
my $resource_json;
my $server = 'https://ohc.lyrasistechnology.org/staff/api';

while (<>) {
  chomp;
  if ($_ =~ m/http/) {
    $res = $_;
    $res =~ s#http://prettyboy.local:4567##;
    my $resourceline = $server . $res;
    print "read " . $resourceline . "\n";
    my $resource_request =  HTTP::Request->new(GET => $resourceline);
    $resource_request->header('X-ArchivesSpace-Session' => $token);
    my $resource_response = $ua->request($resource_request);
    if ($resource_response->is_success) {
      $resource = decode_json($resource_response->decoded_content);
      #print Dumper($resource) . "\n";
      $resource_json = encode_json($resource);
      #print $resource_json . "\n";
    } else {
      print $resource_response->status_line, "\n";
      print "On $resourceline\n";
    }
  } elsif ($_ =~ m/top_containers/) {
    my $container_uri = $_;
        my $instance = {
      jsonmodel_type => 'instance',
      instance_type => 'paper or audiovisual',
      sub_container => {
        jsonmodel_type => 'sub_container',
        top_container => { ref => $container_uri }
      }
    };
    push @{$resource->{instances}}, $instance;
  } elsif ($_ =~ m/end/) {
    $resource_json = encode_json($resource);
    #print $resource_json . "\n";
    my $resourceline = $server . $res;
    print "write " . $resourceline . "\n";
    my $resource_post =  HTTP::Request->new(POST => $resourceline);
    $resource_post->header('X-ArchivesSpace-Session' => $token);
    $resource_post->content_type('application/json');
    $resource_post->content($resource_json);

    my $post_response = $ua->request($resource_post);

    if ($post_response->is_success) {
      print $post_response->decoded_content, "\n";
    } else {
      print $post_response->status_line, "\n";
    }
  } else {
    print "Why are we here?\n";
  }
}


