#!/usr/bin/env perl
#
use strict;
use warnings;
use LWP::UserAgent;
use JSON;
use Text::CSV_XS;
use Data::Dumper;

my $token = '4fb88aa28856cc0050f8e4f2b50ee2a44c3e139bd87daff23bd949146641ec46';
my $ua = LWP::UserAgent->new;
my @rows;
my $prevres = "";
my $csv = Text::CSV_XS->new ( { binary => 1, allow_whitespace => 1 } )  # should set binary attribute.
               or die "Cannot use CSV: ".Text::CSV_XS->error_diag ();

open my $fh, "<:encoding(utf8)", "dogs.csv" or die "can't open csv";
my @cols = @{$csv->getline ($fh)};
$csv->column_names (@cols);

while (my $row = $csv->getline_hr($fh)) {
  print $row->{ID} . "\n";
  my $subject = { jsonmodel_type => 'event',
                  linked_agents => [{
                      role => $row->{ROLE},
                      ref => $row->{AGENT} }],
                  linked_records => [{
                      role => 'source',
                      ref => $row->{ID} }],
                  date => {
                    begin => $row->{DATE},
                    date_type => 'single',
                    label => 'event',
                    jsonmodel_type => 'date'
                  },
                  event_type => $row->{TYPE},
                  outcome => "fulfilled",
                  outcome_note => 'Past Perfect Migration 2019'
               };

  #print (Dumper($agent));

  my $subjectline = 'http://localhost:8089/repositories/2/events';

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

  

