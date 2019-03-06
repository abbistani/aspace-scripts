#!/usr/bin/env perl

use strict;
use warnings;

use Text::CSV_XS;
use XML::Writer;
use IO::File;

my @rows;
my $csv = Text::CSV_XS->new ( { binary => 1 } )  # should set binary attribute.
               or die "Cannot use CSV: ".Text::CSV_XS->error_diag ();
			   
open my $fh, "<:encoding(utf8)", "test.csv" or die "test.csv: $!";
my @cols = @{$csv->getline ($fh)};
$csv->column_names (@cols);

while (my $row = $csv->getline_hr($fh)) {
	print "$row->{resource_id}\n";
  next unless $row->{resource_level} eq "collection";
  my $filename = $row->{resource_id};
  $filename =~ s/[\/\s]/_/g;
	my $output = IO::File->new(">$filename.xml");
	$output->binmode(":utf8");
	my $writer = XML::Writer->new(OUTPUT => $output,  DATA_INDENT => 1, DATA_MODE => 1);
	$writer->xmlDecl("UTF-8");
	$writer->doctype("ead","+//ISBN 1-931666-00-8//DTD ead.dtd Encoded Archival Description (EAD) Version 2002//EN","ead.dtd");
	$writer->startTag("ead");
	$writer->startTag("eadheader", langencoding => "iso639-2", audience => "internal", countryencoding => "iso3166-1", dateencoding => "iso8601", repositoryencoding => "iso15511", scriptencoding => "iso15924");
	$writer->startTag("eadid", countrycode => $row->{country_id}, mainagencycode => $row->{repo_id});
	$writer->endTag("eadid");
	$writer->startTag("filedesc");
	$writer->startTag("titlestmt");
	$writer->dataElement("titleproper", $row->{title});
	$writer->endTag("titlestmt");
	$writer->endTag("filedesc");
  #$writer->startTag("profiledesc");
  #$writer->dataElement("descrules", $row->{descrules});
  #$writer->endTag("profiledesc");
	$writer->endTag("eadheader");
	$writer->startTag("archdesc", level => "collection", type => "inventory");
	$writer->startTag("did");
  #$writer->startTag("repository");
  #$writer->dataElement("corpname",$row->{repo_name});
  #$writer->endTag("repository");
  #$writer->dataElement("origination",$row->{creator1});
  #if ($row->{creator2}) {
  #		$writer->dataElement("origination",$row->{creator2});
  #}
	$writer->dataElement("unittitle",$row->{title});
  #$writer->dataElement("unitdate",$row->{dates});
  #$writer->startTag("physdesc");
  #$writer->dataElement("extent",$row->{extent_ft});
  #$writer->dataElement("extent",$row->{extent_ct});
  #$writer->endTag("physdesc");
  if ($row->{physloc}) {
    $writer->dataElement("physloc",$row->{physloc});
  }
	$writer->dataElement("unitid", $row->{resource_id});
#	$writer->startTag("langmaterial");
#	$writer->dataElement("language", "English", langcode=>$row->{langmaterial});
#	$writer->endTag("langmaterial");
	$writer->endTag("did");
	if ($row->{bioghist}) {
    $writer->startTag("bioghist");
    $writer->dataElement("p",$row->{bioghist});
    $writer->endTag("bioghist");
  }
	if ($row->{scopecontent}) {
		$writer->startTag("scopecontent");
		$writer->dataElement("p",$row->{scopecontent});
		$writer->endTag("scopecontent");
	}
#	if ($row->{arrangement}) {
#		$writer->startTag("arrangement");
#		$writer->dataElement("p",$row->{arrangement});
#		$writer->endTag("arrangement");
#	}
	if ($row->{phystech}) {
		$writer->startTag("phystech");
		$writer->dataElement("p",$row->{phystech});
		$writer->endTag("phystech");
	}
	if ($row->{accessrestrict}) {
		$writer->startTag("accessrestrict");
		$writer->dataElement("p",$row->{accessrestrict});
		$writer->endTag("accessrestrict");
	}
	if ($row->{userestrict}) {
		$writer->startTag("userestrict");
		$writer->dataElement("p",$row->{userestrict});
		$writer->endTag("userestrict");
	}
	if ($row->{userestrict2}) {
		$writer->startTag("userestrict2");
		$writer->dataElement("p",$row->{userestrict2});
		$writer->endTag("userestrict2");
	}
	if ($row->{prefercite}) {
		$writer->startTag("prefercite");
		$writer->dataElement("p",$row->{prefercite});
		$writer->endTag("prefercite");
	}
#	if ($row->{relatedmaterial}) {
#		$writer->startTag("relatedmaterial");
#		$writer->dataElement("p",$row->{relatedmaterial});
#		$writer->endTag("relatedmaterial");
#	}

  if ($row->{subjects}) {
    $writer->startTag("controlaccess");
    my @subjects = split /\;\s*/, $row->{subjects};
    foreach my $subject (@subjects) {
      $writer->dataElement("subject",$subject);
    }
    $writer->endTag("controlaccess");
  }
 	if ($row->{custodhist}) {
 		$writer->startTag("custodhist");
 		$writer->dataElement("p",$row->{custodhist});
  	$writer->endTag("custodhist");
	}
 	if ($row->{originalsloc}) {
 		$writer->startTag("originalsloc");
 		$writer->dataElement("p",$row->{originalsloc});
  	$writer->endTag("originalsloc");
	}
#	if ($row->{acqinfo}) {
#		$writer->startTag("acqinfo");
#		$writer->dataElement("p",$row->{acqinfo});
#		$writer->endTag("acqinfo");
#	}
#	if ($row->{processinfo}) {
#		$writer->startTag("processinfo");
#		$writer->dataElement("p",$row->{processinfo});
#		$writer->endTag("processinfo");
#	}
#  if ($row->{accruals}) {
#		$writer->startTag("accruals");
#		$writer->dataElement("p",$row->{accruals});
#		$writer->endTag("accruals");
#	}
	$writer->endTag("archdesc");
	$writer->endTag("ead");
	$writer->end();

}
$csv->eof or $csv->error_diag();
close $fh;

