#!/usr/bin/env perl
#
use strict;
use warnings;
use LWP::UserAgent;
use JSON;
use Text::CSV_XS;
use Data::Dumper;

my $token = '2d9c84c4cdea13d36f5cc17d66161151275007a0997c82734b572a1abda7b478';
my $ua = LWP::UserAgent->new;
my @rows;
my $prevres = "";
my $csv = Text::CSV_XS->new ( { binary => 1, allow_whitespace => 1 } )  # should set binary attribute.
               or die "Cannot use CSV: ".Text::CSV_XS->error_diag ();

open my $fh, "<:encoding(utf8)", "corpnames.csv" or die "corpnames.csv";
my @cols = @{$csv->getline ($fh)};
$csv->column_names (@cols);

while (my $row = $csv->getline_hr($fh)) {
  print $row->{COMPANY} . "\n";
  my $agent = { jsonmodel_type => 'agent_corporate_entity',
                publish => \1,
                names => [{
                  jsonmodel_type => 'name_corporate_entity',
                  primary_name => $row->{COMPANY},
                  sort_name => $row->{COMPANY},
                  source => 'local',
                  rules => 'local',
                  authority_id => $row->{IDNO}
                }]
               };
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
        };
      push @{$agent->{agent_contacts}}, $contact;
    }

  if ($row->{PHONECELL}) {
    my $telephone = {
      jsonmodel_type => 'telephone',
      number_type => 'cell',
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


  #print (Dumper($agent));

  my $agentline = 'http://prettyboy.local:4567//agents/corporate_entities';

  my $agent_json = encode_json($agent);
  my $agent_post =  HTTP::Request->new(POST => $agentline);
  $agent_post->header('X-ArchivesSpace-Session' => $token);
  $agent_post->content_type('application/json');
  $agent_post->content($agent_json);

  my $post_response = $ua->request($agent_post);

  if ($post_response->is_success) {
    print $post_response->decoded_content, "\n";
  } else {
    print $post_response->decoded_content, "\n";
  }

}

  

