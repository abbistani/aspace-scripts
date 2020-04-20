#!/usr/bin/env perl
#
use strict;
use warnings;
use LWP::UserAgent;
use JSON;
use Data::Dumper;
use Text::CSV_XS;

my $token = 'f77c1cc5838aade626ff4337769c17952ef7f45fbb8bffcdd7ea56d20548448a';
my $ua = LWP::UserAgent->new;
my $acc;
my $acc_json;
my $instance;
my $server = 'https://alh.archives.dcl.org/staff/api';

my $csv = Text::CSV_XS->new ( { binary => 1, allow_whitespace => 1 } )  # should set binary attribute.
               or die "Cannot use CSV: ".Text::CSV_XS->error_diag ();

open my $fh, "<:encoding(utf8)", "missing-fix.csv" or die "csv failed";
my @cols = @{$csv->getline ($fh)};
$csv->column_names (@cols);

while (my $row = $csv->getline_hr($fh)) {
  my $id = $row->{ID};
  my $accline = $server . $id;
  my $acc_request = HTTP::Request->new(GET => $accline);
  $acc_request->header('X-ArchivesSpace-Session' => $token);
  my $acc_response = $ua->request($acc_request);
  if ($acc_response->is_success) {
      $acc = decode_json($acc_response->decoded_content);
      #print Dumper($acc) . "\n";
    } else {
      print $acc_response->status_line, "\n";
      print "On $accline\n";
    }

    my %container = ( jsonmodel_type => 'top_container',
                  indicator => $row->{CNO},
                  type => $row->{CTYPE} );
    if ( $row->{loc_uri}) {
      $container{container_locations} = [{ref => $row->{loc_uri},
                                          status => 'current',
                                          start_date => '2019-07-22'}];
    }
    my $container_json = encode_json(\%container);

    my $request = HTTP::Request->new(POST => $server . '/repositories/2/top_containers');
    $request->header('X-ArchivesSpace-Session' => $token);
    $request->content_type('application/json');
    $request->content($container_json);
    #print Dumper($container_json) . "\n";
  
    my $response = $ua->request($request);

    if ($response->is_success) {
      print $response->decoded_content, "\n";
      my $feedback = decode_json($response->decoded_content);
      my $container_uri = $feedback->{uri};
      $instance = {
        jsonmodel_type => 'instance',
        instance_type => $row->{TYPE},
        sub_container => {
          jsonmodel_type => 'sub_container',
          top_container => { ref => $container_uri }
        }};
      push @{$acc->{instances}}, $instance;
      #print Dumper($acc) . "\n";

      $acc_json = encode_json($acc);
    } else {
      print $response->decoded_content, "\n";
    }

  my $acc_post =  HTTP::Request->new(POST => $accline);
  $acc_post->header('X-ArchivesSpace-Session' => $token);
  $acc_post->content_type('application/json');
  $acc_post->content($acc_json);
  #print $acc_json . "\n";

  my $post_response = $ua->request($acc_post);

  if ($post_response->is_success) {
    print $post_response->decoded_content, "\n";
  } else {
    print $post_response->status_line, "\n";
  }
}



