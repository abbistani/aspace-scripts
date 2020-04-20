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
  my $resource_json;
  my @working_list;
  my $server = 'http://localhost:8089';
  
  my $listline = $server . '/repositories/3/accessions?all_ids=true';
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

  #@working_list = qw/ 38 /;

foreach my $id (@working_list) {  
  my $resource = {jsonmodel_type => 'resource',
                  level => 'collection',
                  resource_type => 'collection',
                  publish => \1,
                  lang_materials => [{jsonmodel_type => 'lang_material',
                    language_and_script => {jsonmodel_type => 'language_and_script',
                      language => 'eng'}}],
                  finding_aid_language => 'eng',
                  finding_aid_script => 'Latn',
                  notes => [
                    {jsonmodel_type => 'note_multipart',
                      type => 'accessrestrict',
                      subnotes => [
                        {jsonmodel_type => 'note_text',
                          content => 'This collection is open for research.',
                          publish => \1}],
                      publish => \1},
                    {jsonmodel_type => 'note_multipart',
                      type => 'userestrict',
                      subnotes => [
                       {jsonmodel_type => 'note_text',
                        content => 'Materials are available for use in the Richardson-Sloane Special Collections Center only.

Request permission before copying materials.

Personal digital cameras and scanners are allowed in the Richardson-Sloane Special Collections Center on a case-by-case basis. The items that a researcher may want to scan or photograph must be examined and evaluated for physical condition, copyright issues, and donor restrictions by staff.

Copyright restrictions may apply; please consult Special Collections staff for further information.

The copyright law of the United States (title 17, United States Code) governs the making of reproductions of copyrighted material.

Under certain conditions specified in the law, libraries and archives are authorized to furnish a reproduction. One of these specific conditions is that the reproduction is not to be "used for any purpose other than private study, scholarship, or research." If a user makes a request for, or later uses, a reproduction for purposes in excess of "fair use," that user may be liable for copyright infringement.',
                        publish => \1}],
                      publish => \1},
                    {jsonmodel_type => 'note_multipart',
                      type => 'prefercite',
                      subnotes => [
                        {jsonmodel_type => 'note_text',
                         content => '[Identification of Item], [Collection Name], [Collection #], Richardson-Sloane Special Collections Center, Davenport Public Library, Davenport, Iowa.',
                         publish => \1}],
                     publish => \1},
                   {jsonmodel_type => 'note_multipart',
                     type => 'acqinfo',
                     subnotes => [
                       {jsonmodel_type => 'note_text',
                        content => 'Gift',
                        publish => \1}],
                    publish => \1}
                ]}; 
  my $accession;
  my $accessionline = $server . '/repositories/3/accessions/' . $id;
  print "processing $accessionline\n";
  my $accession_request =  HTTP::Request->new(GET => $accessionline);
  $accession_request->header('X-ArchivesSpace-Session' => $token);
  my $accession_response = $ua->request($accession_request);
  if ($accession_response->is_success) {
    $accession = decode_json($accession_response->decoded_content);
    $resource->{title} = $accession->{title};
    $resource->{id_0} = $accession->{id_0};
    $resource->{id_1} = $accession->{id_1};
    $resource->{id_2} = $accession->{id_2};

    if (scalar(@{$accession->{dates}}) > 0) {
      $resource->{dates} = $accession->{dates};
    } else {
      $resource->{dates} = [{jsonmodel_type => 'date', expression => '[unknown]', label => 'creation', date_type => 'inclusive'}];
    }

    if (scalar(@{$accession->{extents}}) > 0) {
      $resource->{extents} = $accession->{extents};
    } else {
      $resource->{extents} = [{jsonmodel_type => 'extent', number => '1', extent_type => 'unknown', portion => 'whole'}];
    }

    if ($accession->{content_description}) {
      my $content_text = $accession->{content_description};
      my $content_note = {jsonmodel_type => 'note_multipart', type => 'scopecontent', subnotes => [{jsonmodel_type => 'note_text', content => $content_text, publish => \1}], publish => \1};
      push @{$resource->{notes}}, $content_note;
    }
    if ($accession->{inventory}) {
      my $inventory_text = $accession->{inventory};
      my $inventory_note = {jsonmodel_type => 'note_multipart', type => 'scopecontent', subnotes => [{jsonmodel_type => 'note_text', content => $inventory_text, publish => \1}], publish => \1};
      push @{$resource->{notes}}, $inventory_note;
    }
    if ($accession->{condition_description}) {
      my $condition_text = $accession->{condition_description};
      my $condition_note = {jsonmodel_type => 'note_singlepart', type => 'physdesc', content => [$condition_text], publish => \1};
      push @{$resource->{notes}}, $condition_note;
    }
    if ( $accession->{user_defined}->{text_3}) {
      my $physloc_text = $accession->{user_defined}->{text_3};
      my $physloc_note = {jsonmodel_type => 'note_singlepart', type => 'physloc', content => [$physloc_text], publish => \1};
      push @{$resource->{notes}}, $physloc_note;
    }
    if ($accession->{disposition}) {
      my $dispo_text = $accession->{disposition};
      my $dispo_note = {jsonmodel_type => 'note_multipart', type => 'separatedmaterial', subnotes => [{jsonmodel_type => 'note_text', content => $dispo_text, publish => \1}], publish => \1};
      push @{$resource->{notes}}, $dispo_note;
    }
    if ($accession->{provenance}) {
      my $provo_text = $accession->{provenance};
      my $provo_note = {jsonmodel_type => 'note_multipart', type => 'custodhist', subnotes => [{jsonmodel_type => 'note_text', content => $provo_text, publish => \0}], publish => \0};
      push @{$resource->{notes}}, $provo_note;
    }
    if ($accession->{general_note}) {
      my $gen_text = $accession->{general_note};
      my $gen_note = {jsonmodel_type => 'note_multipart', type => 'odd', subnotes => [{jsonmodel_type => 'note_text', content => $gen_text, publish => \1}], publish => \1};
      push @{$resource->{notes}}, $gen_note;
    }
    if ($accession->{rights_statements}) {
      $resource->{rights_statements} = $accession->{rights_statements};
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
    print $accession_response->status_line, "\n";
    print "On $accessionline\n";
  }

  if (1) {
    my $postline = $server . '/repositories/4/resources';
    #print "$postline . \n";
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
