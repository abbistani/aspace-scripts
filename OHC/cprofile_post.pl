#!/usr/bin/env perl
#
use strict;
use warnings;
use LWP::UserAgent;
use JSON;
use Text::CSV_XS;



my $token = '9d29e80239eb9b939494a456ae533024c97c5924b8d06088d347fc448c94b9b9';
my $ua = LWP::UserAgent->new;
my @rows;
my $csv = Text::CSV_XS->new ( { binary => 1, allow_whitespace => 1 } )  # should set binary attribute.
               or die "Cannot use CSV: ".Text::CSV_XS->error_diag ();

open my $fh, "<:encoding(utf8)", "container_types-xlsx.csv" or die "container_types-xlsx.csv";
my @cols = @{$csv->getline ($fh)};
$csv->column_names (@cols);

while (my $row = $csv->getline_hr($fh)) {
  my %profile = ( jsonmodel_type => 'container_profile',
                  name => $row->{name},
                  dimension_units => 'inches',
                  extent_dimension => 'width',
                  depth => $row->{depth},
                  width => $row->{width},
                  height => $row->{height} );
  my $profile_json = encode_json(\%profile);

  my $request = HTTP::Request->new(POST => 'http://prettyboy.local:4567/container_profiles');
  $request->header('X-ArchivesSpace-Session' => $token);
  $request->content_type('application/json');
  $request->content($profile_json);
  
  my $response = $ua->request($request);

  if ($response->is_success) {
    print $response->decoded_content, "\n";
  } else {
    print $response->status_line, "\n";
  }
}

$csv->eof or $csv->error_diag();
close $fh;

