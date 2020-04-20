#!/usr/bin/env perl
#
use strict;
use warnings;
use LWP::UserAgent;
use JSON;
use Text::CSV_XS;
use Data::Dumper;

my $token = 'a848440c3f77a674e3ead0cd4f34c727f0c80ac0c2b26e7d4af092f2e7e205e0';
my $ua = LWP::UserAgent->new;
my @rows;
my $prevres = "";
my $csv = Text::CSV_XS->new ( { binary => 1, allow_whitespace => 1 } )  # should set binary attribute.
               or die "Cannot use CSV: ".Text::CSV_XS->error_diag ();

open my $fh, "<:encoding(utf8)", "corpnames.csv" or die "corpnames.csv";
my @cols = @{$csv->getline ($fh)};
$csv->column_names (@cols);

while (my $row = $csv->getline_hr($fh)) {
  my %agent = ( jsonmodel_type => 'name_corporate_entity',
                primary_name => $row->{COMPANY},
                source => 'local',
                rules => 'local',
                authority_id => $row->{IDNO};
               );
  if ($row->{NOTES}) {
    my $note = {
       jsonmodel_type => 'note_bioghist',
       subnotes => [ { jsonmodel_type => 'note_text',
                        content => $row->{NOTES}
                      }]
       };
    push @{$agent->{notes}[0]}, $note;
  }
  if ($row->{ADDRESS1}) {
      my $contact = {
        jsonmodel_type => 'agent_contact',
        name => $row->{COMPANY},
        address_1 => $row->{ADDRESS1},
        address_2 => $row->{ADDRESS2},
        city => $row->{CITY},
        region => $row->{STATE},
        post_code => $row->{ZIP},
        note => $row->{WEBSITE}
        },
    }

  if ($row->{PHONECELL}) {
    my $telephone = {
      jsonmodel_type => 'telephone',
      number_type => 'mobile',
      number => $row->{PHONECELL}
    };
    push @{$agent->{agent_contacts}[0]->{telephones}}, $telephone;
  }
  if ($row->{PHONEW}) {
    my $telephone = {
      jsonmodel_type => 'telephone',
      number_type => 'business',
      number => $row->{PHONEW}
    };
    push @{$agent->{agent_contacts}[0]->{telephones}}, $telephone;
  }
  if ($row->{FAXNO}) {
    my $telephone = {
      jsonmodel_type => 'telephone',
      number_type => 'fax',
      number => $row->{FAXNO}
    };
    push @{$agent->{agent_contacts}[0]->{telephones}}, $telephone;
  }
  if ($row->{PHONEH}) {
    my $telephone = {
      jsonmodel_type => 'telephone',
      number_type => 'home',
      number => $row->{PHONEH}
    };
    push @{$agent->{agent_contacts}[0]->{telephones}}, $telephone;
  }


  my $agent_id = $row->{id};
  my $agentline = 'http://localhost:8089/agents/people/' . $agent_id;
  my $agent_request = HTTP::Request->new(GET => $agentline);
  $agent_request->header('X-ArchivesSpace-Session' => $token);
  my $agent_response = $ua->request($agent_request);
  if ($agent_response->is_success) {
    $agent = decode_json($agent_response->decoded_content);
  } else {
    print $agent_response->status_line, "\n";
    print "On $agentline\n";
  }


  $agent_json = encode_json($agent);
  my $agent_post =  HTTP::Request->new(POST => $agentline);
  $agent_post->header('X-ArchivesSpace-Session' => $token);
  $agent_post->content_type('application/json');
  $agent_post->content($agent_json);

  my $post_response = $ua->request($agent_post);

  if ($post_response->is_success) {
    print $post_response->decoded_content, "\n";
  } else {
    print $post_response->status_line, "\n";
  }

}

  

