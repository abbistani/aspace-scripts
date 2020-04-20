#!/usr/bin/env perl
#
use strict;
use warnings;
use LWP::UserAgent;
use JSON;
use Text::CSV_XS;
use Data::Dumper;

my $token = 'bd17c5db61702bb3e009cfb50cc2fe7cf17f01e5ce1a7cf1186886fe5e3ecc6e';
my $ua = LWP::UserAgent->new;
my @rows;
my $prevres = "";
my $csv = Text::CSV_XS->new ( { binary => 1, allow_whitespace => 1 } )  # should set binary attribute.
               or die "Cannot use CSV: ".Text::CSV_XS->error_diag ();

open my $fh, "<:encoding(utf8)", "geographics.csv" or die "geographics.csv";
my @cols = @{$csv->getline ($fh)};
$csv->column_names (@cols);

while (my $row = $csv->getline_hr($fh)) {
  print $row->{SUBJECT} . "\n";
  my $subject = { jsonmodel_type => 'subject',
                publish => \1,
                source => 'lcsh',
                vocabulary => '/vocabularies/1',
                terms => [{
                  jsonmodel_type => 'term',
                  term => $row->{SUBJECT},
                  term_type => 'geographic',
                  vocabulary => '/vocabularies/1',
                }]
               };

  #print (Dumper($agent));

  my $subjectline = 'http://prettyboy.local:4567/subjects';

  my $subject_json = encode_json($subject);
  my $subject_post =  HTTP::Request->new(POST => $subjectline);
  $subject_post->header('X-ArchivesSpace-Session' => $token);
  $subject_post->content_type('application/json');
  $subject_post->content($subject_json);

  my $post_response = $ua->request($subject_post);

  if ($post_response->is_success) {
    print $post_response->decoded_content, "\n";
  } else {
    print $post_response->decoded_content, "\n";
  }

}

  

