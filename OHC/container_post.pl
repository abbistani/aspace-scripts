#!/usr/bin/env perl
#
use strict;
use warnings;
use LWP::UserAgent;
use JSON;
use Text::CSV_XS;
use Data::Dumper;



my $token = '93964061839115f069d003cfa2c8a65d9b17030d751b6c94260d13993728aaba';
my $server = 'https://aspace.ohiohistory.org/staff/api';
my $ua = LWP::UserAgent->new;
$ua->timeout(600);
my @rows;
my $prevres = "";
my $csv = Text::CSV_XS->new ( { binary => 1, allow_whitespace => 1 } )  # should set binary attribute.
               or die "Cannot use CSV: ".Text::CSV_XS->error_diag ();

open my $fh, "<:encoding(utf8)", "sas-containers-bc-noloc-res.csv" or die "containers.csv";
my @cols = @{$csv->getline ($fh)};
$csv->column_names (@cols);

my $resource;
my $resource_json;
my $instance;

while (my $row = $csv->getline_hr($fh)) {

  my $res = $row->{resource};

    my $resourceline = $server . $res;
    print "read " . $resourceline . "\n";
    my $resource_request =  HTTP::Request->new(GET => $resourceline);
    $resource_request->header('X-ArchivesSpace-Session' => $token);
    my $resource_response = $ua->request($resource_request);
    if ($resource_response->is_success) {
      #print Dumper($resource_response->decoded_content) . "\n";
      $resource = decode_json($resource_response->decoded_content);
      #print Dumper($resource) . "\n";
      $resource_json = encode_json($resource);
      #print $resource_json . "\n";
    } else {
      print $resource_response->status_line, "\n";
      #print $resource_response->decoded_content, "\n";
      print "On $resourceline\n";
    }

  my $tracking;
  my @topcons;
  if ($row->{tracking}) {
    $tracking = $row->{tracking};
  } elsif ($row->{seq}) {
    $tracking = $row->{seq};
  }

  my $indicator;
  if ($row->{box}) {
    $indicator = $row->{box};
  } elsif ($row->{seq}) {
    $indicator = $row->{seq};
  }

  my $type;
  if ($row->{seq}) {
    $type = "item";
  } else {
    $type = "box";
  }

  my %container = ( jsonmodel_type => 'top_container',
                  barcode => $row->{barcode},
                  ils_holding_id => $tracking,
                  indicator => $indicator,
                  type => $type);
  if ( $row->{loc_uri}) {
    $container{container_locations} = [{ref => $row->{loc_uri},
                                          status => 'current',
                                          start_date => $row->{inventoried}}];
  }
  my $container_json = encode_json(\%container);

  my $request = HTTP::Request->new(POST => $server . '/repositories/2/top_containers');
  $request->header('X-ArchivesSpace-Session' => $token);
  $request->content_type('application/json');
  $request->content($container_json);
    print Dumper($container_json) . "\n";
  
  my $response = $ua->request($request);

  if ($response->is_success) {
    print $response->decoded_content, "\n";
    my $feedback = decode_json($response->decoded_content);
    my $container_uri = $feedback->{uri};
    $instance = {
      jsonmodel_type => 'instance',
      instance_type => 'paper or audiovisual',
      sub_container => {
        jsonmodel_type => 'sub_container',
        top_container => { ref => $container_uri }
      }
    };
    push @{$resource->{instances}}, $instance;
    #print Dumper($resource) . "\n";

    $resource_json = encode_json($resource);
    #print $resource_json . "\n";
    #my $resourceline = $server . $res;
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
    print $response->status_line, "\n";
    print $response->decoded_content, "\n";
  }

}

$csv->eof or $csv->error_diag();
close $fh;

