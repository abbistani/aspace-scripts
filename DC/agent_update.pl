#!/usr/bin/env perl
#
use strict;
use warnings;
use LWP::UserAgent;
use JSON;
use Data::Dumper;
use Text::CSV_XS;

my $token = '01e5623e96a2f5f9c29831623077e07f9892483945f951adeeecd153d7753cef';
my $ua = LWP::UserAgent->new;
my $agent;
my $agent_json;
my $server = 'https://alh.archives.dcl.org/staff/api';

my $csv = Text::CSV_XS->new ( { binary => 1, allow_whitespace => 1 } )  # should set binary attribute.
               or die "Cannot use CSV: ".Text::CSV_XS->error_diag ();

open my $fh, "<:encoding(utf8)", "prefixes.csv" or die "can't open csv";
my @cols = @{$csv->getline ($fh)};
$csv->column_names (@cols);

while (my $row = $csv->getline_hr($fh)) {
  my $id = $row->{ID};
  my $agentline = $server . $id;
  my $agent_request = HTTP::Request->new(GET => $agentline);
  $agent_request->header('X-ArchivesSpace-Session' => $token);
  my $agent_response = $ua->request($agent_request);
  if ($agent_response->is_success) {
      $agent = decode_json($agent_response->decoded_content);
      #print Dumper($agent) . "\n";
      my $prefix = $row->{prefix};
      #print Dumper($email) . "\n";
      $agent->{names}[0]->{prefix} = $prefix;
      #print Dumper($agent) . "\n";
      $agent_json = encode_json($agent);
    } else {
      print $agent_response->status_line, "\n";
      print "On $agentline\n";
    }

  my $agent_post =  HTTP::Request->new(POST => $agentline);
  $agent_post->header('X-ArchivesSpace-Session' => $token);
  $agent_post->content_type('application/json');
  $agent_post->content($agent_json);
  #print $agent_json . "\n";

  my $post_response = $ua->request($agent_post);

  if ($post_response->is_success) {
    print $post_response->decoded_content, "\n";
  } else {
    print $post_response->status_line, "\n";
  }
}
