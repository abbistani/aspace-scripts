#!/usr/bin/env perl
#
use strict;
use warnings;
use LWP::UserAgent;
use JSON;
use Data::Dumper;
use Text::CSV_XS;

my $token = '703a92ce0350330116422a820cefb3b738b19bce3305421ceb76d486834bcf54';
my $ua = LWP::UserAgent->new;
my $acc;
my $acc_json;
my $server = 'http://prettyboy.local:4567';

my $csv = Text::CSV_XS->new ( { binary => 1, allow_whitespace => 1 } )  # should set binary attribute.
               or die "Cannot use CSV: ".Text::CSV_XS->error_diag ();

open my $fh, "<:encoding(utf8)", "subject-load.csv" or die "subject-loadcsv";
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
      print Dumper($acc) . "\n";
      my $subject = {ref => $row->{SUBJID}};
      print Dumper($subject) . "\n";
      push @{$acc->{subjects}}, $subject;
      #print Dumper($acc) . "\n";
      $acc_json = encode_json($acc);
    } else {
      print $acc_response->status_line, "\n";
      print "On $accline\n";
    }

  my $acc_post =  HTTP::Request->new(POST => $accline);
  $acc_post->header('X-ArchivesSpace-Session' => $token);
  $acc_post->content_type('application/json');
  $acc_post->content($acc_json);
  print $acc_json . "\n";

  my $post_response = $ua->request($acc_post);

  if ($post_response->is_success) {
    print $post_response->decoded_content, "\n";
  } else {
    print $post_response->status_line, "\n";
  }
}



