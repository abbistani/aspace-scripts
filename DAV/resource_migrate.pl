#!/usr/bin/env perl
#
use strict;
use warnings;
use LWP::UserAgent;
use JSON;
use Data::Dumper;

my $token = '31e0e29b3bb057a57332e82b53bb02143b7ecde46145701d4677f1f4fe8ced71';
my $ua = LWP::UserAgent->new;

  my $resource_uri;
  my $resource;
  my $resource_json;
  my @working_list;
  my $server = 'http://localhost:8089';
  
  my $listline = $server . '/repositories/3/resources?all_ids=true';
  my $listrequest = HTTP::Request->new(GET => $listline);
  $listrequest->header('X-ArchivesSpace-Session' => $token);
  my $list_response = $ua->request($listrequest);

  if ($list_response->is_success) {
    print $list_response->decoded_content, "\n";
    my $idlist = $list_response->decoded_content;
    $idlist =~ s/[\[\]]//g;
    @working_list = split /,/, $idlist;
  } else {
    print $list_response->status_line, "\n";
    print "On $listline\n";
  }

    @working_list = qw/ 15 /;

foreach my $id (@working_list) {  
  my $resourceline = $server . '/repositories/3/resources/' . $id;
  print "processing $resourceline\n";
  my $resource_request =  HTTP::Request->new(GET => $resourceline);
  $resource_request->header('X-ArchivesSpace-Session' => $token);
  my $resource_response = $ua->request($resource_request);
  if ($resource_response->is_success) {
    $resource = decode_json($resource_response->decoded_content);
    #print Dumper($resource) . "\n";
    delete $resource->{linked_events};
    delete $resource->{revision_statements};
    delete $resource->{rights_statements};
    delete $resource->{classifications};
    delete $resource->{collection_management};
    delete $resource->{related_accessions};
    delete $resource->{finding_aid_title};
    delete $resource->{finding_aid_note};
    $resource->{publish} = \1;
    if ($resource->{repository_processing_note}) {
      my $repo_proc_text = $resource->{repository_processing_note};
      my $repo_proc_note = {jsonmodel_type => 'note_multipart', type => 'odd', subnotes => [{jsonmodel_type => 'note_text', content => $repo_proc_text}]};
      push @{$resource->{notes}}, $repo_proc_note;
      delete $resource->{repository_processing_note};
    }
    if ($resource->{finding_aid_date}) {
      my $repo_proc_text = $resource->{finding_aid_date};
      my $repo_proc_note = {jsonmodel_type => 'note_multipart', type => 'odd', subnotes => [{jsonmodel_type => 'note_text', content => $repo_proc_text}]};
      push @{$resource->{notes}}, $repo_proc_note;
      delete $resource->{finding_aid_date};
    }
    if ($resource->{finding_aid_author}) {
      my $repo_proc_text = $resource->{finding_aid_author};
      my $repo_proc_note = {jsonmodel_type => 'note_multipart', type => 'odd', subnotes => [{jsonmodel_type => 'note_text', content => $repo_proc_text}]};
      push @{$resource->{notes}}, $repo_proc_note;
      delete $resource->{finding_aid_author};
    }
    if ($resource->{finding_aid_status}) {
      my $repo_proc_text = $resource->{finding_aid_status};
      my $repo_proc_note = {jsonmodel_type => 'note_multipart', type => 'odd', subnotes => [{jsonmodel_type => 'note_text', content => $repo_proc_text}]};
      push @{$resource->{notes}}, $repo_proc_note;
      delete $resource->{finding_aid_status};
    }

    my $index = 0;
    foreach my $ed (@{$resource->{external_documents}}) {
      if ($ed->{location} !~ m/cdm/) {
        splice (@{$resource->{external_documents}},$index,1);
      }  
      $index++; 
    }

    foreach my $note (@{$resource->{notes}}) {
      if ($note->{type} eq 'acqinfo') {
        $note->{type} = 'custodhist';
        $note->{published} = \0;
      }
      if ($note->{label} && ($note->{label} eq 'Content Description')) {
        delete $note->{label};
      }
    }

    if (@{$resource->{extents}}[0]->{physical_details}) {
      my $physloc_text = @{$resource->{extents}}[0]->{physical_details};
      my $physloc_note = {jsonmodel_type => 'note_singlepart', type => 'physloc', content => [$physloc_text], publish => \1};
      push @{$resource->{notes}}, $physloc_note;
      delete(@{$resource->{extents}}[0]->{physical_details});
    }

    #print Dumper(@{$resource->{notes}}) . "\n";
    $resource_json = encode_json($resource);
    #print $resource_json . "\n";
  } else {
    print $resource_response->status_line, "\n";
    print "On $resourceline\n";
  }

  if (1) {
    my $postline = $server . '/repositories/4/resources';
    my $resource_post =  HTTP::Request->new(POST => $postline);
    $resource_post->header('X-ArchivesSpace-Session' => $token);
    $resource_post->content_type('application/json');
    $resource_post->content($resource_json);
    #print $resource_json . "\n";

    my $post_response = $ua->request($resource_post);

    if ($post_response->is_success) {
      print $post_response->decoded_content, "\n";
    } else {
      print $post_response->status_line, "\n";
      print $post_response->decoded_content, "\n";
    }
  }
}
