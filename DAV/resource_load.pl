#!/usr/bin/env perl
#
use strict;
use warnings;
use LWP::UserAgent;
use JSON;
use Text::CSV_XS;
use Data::Dumper;

my $token = 'aaa03643d8a7073c0c7f216bc83a1335ae1162322c736a65d03d10cfdc9267ea';
my $ua = LWP::UserAgent->new;

  my $resource_uri;
  my $resource_json;
  my @working_list;
  my $server = 'http://localhost:8089';

my @rows;
my $prevres = "";
my $csv = Text::CSV_XS->new ( { binary => 1, allow_whitespace => 1 } )  # should set binary attribute.
               or die "Cannot use CSV: ".Text::CSV_XS->error_diag ();

open my $fh, "<:encoding(utf8)", "accload.csv" or die "can't open csv";
my @cols = @{$csv->getline ($fh)};
$csv->column_names (@cols);
  
while (my $row = $csv->getline_hr($fh)) {
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

    $resource->{title} = $row->{TITLE};
    $resource->{id_0} = $row->{ID0};
    $resource->{id_1} = $row->{ID1};

    if ($row->{DATE}) {
      $resource->{dates} = [{jsonmodel_type => 'date', expression => $row->{DATE}, label => 'creation', date_type => 'inclusive'}];
    } else {
      $resource->{dates} = [{jsonmodel_type => 'date', expression => '[unknown]', label => 'creation', date_type => 'inclusive'}];
    }

    if ($row->{EXTENT}) {
      $resource->{extents} = [{jsonmodel_type => 'extent', number => '1', extent_type => 'unknown', portion => 'whole', container_summary => $row->{EXTENT}}];
    } else {
      $resource->{extents} = [{jsonmodel_type => 'extent', number => '1', extent_type => 'unknown', portion => 'whole'}];
    }

    if ($row->{SCOPE}) {
      my $content_text = $row->{SCOPE};
      my $content_note = {jsonmodel_type => 'note_multipart', type => 'scopecontent', subnotes => [{jsonmodel_type => 'note_text', content => $content_text, publish => \1}], publish => \1};
      push @{$resource->{notes}}, $content_note;
    }
    if ($row->{PHYSDESC}) {
      my $condition_text = $row->{PHYSDESC};
      my $condition_note = {jsonmodel_type => 'note_singlepart', type => 'physdesc', content => [$condition_text], publish => \1};
      push @{$resource->{notes}}, $condition_note;
    }
    if ($row->{PHYSLOC}) {
      my $physloc_text = $row->{PHYSLOC};
      my $physloc_note = {jsonmodel_type => 'note_singlepart', type => 'physloc', content => [$physloc_text], publish => \1};
      push @{$resource->{notes}}, $physloc_note;
    }
    if ($row->{PHYSLOC2}) {
      my $physloc_text = $row->{PHYSLOC2};
      my $physloc_note = {jsonmodel_type => 'note_singlepart', type => 'physloc', content => [$physloc_text], publish => \1};
      push @{$resource->{notes}}, $physloc_note;
    }
    if ($row->{CUSTODIAL}) {
      my $provo_text = $row->{CUSTODIAL};
      my $provo_note = {jsonmodel_type => 'note_multipart', type => 'custodhist', subnotes => [{jsonmodel_type => 'note_text', content => $provo_text, publish => \0}], publish => \0};
      push @{$resource->{notes}}, $provo_note;
    }
    if ($row->{PROCSTAT}) {
      my $gen_text = $row->{PROCSTAT};
      my $gen_note = {jsonmodel_type => 'note_multipart', type => 'odd', subnotes => [{jsonmodel_type => 'note_text', content => $gen_text, publish => \1}], publish => \1};
      push @{$resource->{notes}}, $gen_note;
    }
    if ($row->{FINDAID}) {
      my $gen_text = $row->{FINDAID};
      my $gen_note = {jsonmodel_type => 'note_multipart', type => 'odd', subnotes => [{jsonmodel_type => 'note_text', content => $gen_text, publish => \1}], publish => \1};
      push @{$resource->{notes}}, $gen_note;
    }
    if ($row->{DIGLOC}) {
      my $gen_text = $row->{DIGLOC};
      my $gen_note = {jsonmodel_type => 'note_multipart', type => 'odd', subnotes => [{jsonmodel_type => 'note_text', content => $gen_text, publish => \1}], publish => \1, label => 'Digital Storage Location'};
      push @{$resource->{notes}}, $gen_note;
    }
    #print Dumper(@{$resource->{notes}}) . "\n";
    $resource_json = encode_json($resource);
    #print $resource_json . "\n";

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
