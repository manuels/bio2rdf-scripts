###############################################################################
#Copyright (C) 2011 Alison Callahan, Marc-Alexandre Nolin
#
#Permission is hereby granted, free of charge, to any person obtaining a copy of
#this software and associated documentation files (the "Software"), to deal in
#the Software without restriction, including without limitation the rights to
#use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
#of the Software, and to permit persons to whom the Software is furnished to do
#so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.
###############################################################################

#!/usr/bin/perl 

use strict;
use Bio::ASN1::EntrezGene;
use Data::Dumper;
use Digest::MD5;

#####
#
# Entrez Genes nquadizer from the ASN.1 file
#
# Usage: zcat [compressed ASN.1 file] | perl ASN1Gene2nq.pl | gzip > [resulting file compressed]
# Example: zcat All_data.asn.gz | perl ASN1Gene2nq.pl | gzip > All_data.nq.gz
#
# Note: You can use the split Linux to cut the huge resulting file in smaller more manageable one
#
# The structure of Entrez Gene ASN.1 file can be found here [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/entrezgene.asn.html]
#
# Base on the Bio::ASN1::EntrezGene parser of Mingyi Liu (c) 2005 [http://www.ncbi.nlm.nih.gov/pubmed/15879451]
# URI: <http://bio2rdf.org/pubmed:15879451>
#
#####

####
# 
# Debug line
# $DB::single=2;
#
####

my $parser = Bio::ASN1::EntrezGene->new('fh' => \*STDIN);
my $i = 0;

our $geneid = "";
our $graph = "";
our $base = "http://bio2rdf.org/geneid";
our $resource = "http://bio2rdf.org/geneid_resource";
our $vocabulary = "http://bio2rdf.org/geneid_vocabulary";
our $rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns";
our $rdfs = "http://www.w3.org/2000/01/rdf-schema";
our $dc = "http://purl.org/dc/terms";
our $foaf = "http://xmlns.com/foaf/0.1";

while(my $doc = $parser->next_seq){

	#this never happens, but doesn't hurt
	unless(defined $doc){
		#print STDERR "bad text for round #".++$i."!\n";
		next;
	}

	#this should always be true
	$doc = $doc->[0] if(ref($doc) eq 'ARRAY');

	# Begin of nQuads creation
	EntrezGene2NQ($doc);
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/entrezgene.asn.html]
sub EntrezGene2NQ{
	my $doc = shift;

	$geneid = $doc->{'track-info'}->[0]->{'geneid'};
	$graph = "http://bio2rdf.org/geneid_record:$geneid";

	printN3("$base:$geneid", "$rdf#type", "$resource:Gene", 0, 0);
	printN3("$base:$geneid", "$vocabulary:geneType", $doc->{'type'}, 1, "^^xsd:string");

	foreach(@{$doc->{'track-info'}}){
		my $uniqueID = generateUniqueURI($_);
		printN3( "$base:$geneid", "$vocabulary:track-info", "$resource:$geneid-$uniqueID", 0, 0);
		printN3( "$resource:$geneid-$uniqueID", "$rdf#type", "$vocabulary:Gene-trak", 0, 0);
		Gene_track($_,"$resource:$geneid-$uniqueID");
	}
	
	foreach(@{$doc->{'source'}}){
		my $uniqueID = generateUniqueURI($_);
		printN3( "$base:$geneid", "$vocabulary:source", "$resource:$geneid-$uniqueID", 0, 0);
		printN3( "$resource:$geneid-$uniqueID", "$rdf#type", "$vocabulary:BioSource", 0, 0);
		BioSource($_,"$resource:$geneid-$uniqueID");
	}
	foreach(@{$doc->{'gene'}}){
		my $uniqueID = generateUniqueURI($_);
		printN3( "$base:$geneid", "$vocabulary:gene", "$resource:$geneid-$uniqueID", 0, 0);
		printN3( "$resource:$geneid-$uniqueID", "$rdf#type", "$vocabulary:Gene-ref", 0, 0);
		Gene_ref($_,"$resource:$geneid-$uniqueID");
	}
	foreach(@{$doc->{'prot'}}){
		my $uniqueID = generateUniqueURI($_);
		printN3( "$base:$geneid", "$vocabulary:prot", "$resource:$geneid-$uniqueID", 0, 0);
		printN3( "$resource:$geneid-$uniqueID", "$rdf#type", "$vocabulary:Prot-ref", 0, 0);
		Prot_ref($_,"$resource:$geneid-$uniqueID");
	}
	foreach(@{$doc->{'rna'}}){
		my $uniqueID = generateUniqueURI($_);
		printN3( "$base:$geneid", "$vocabulary:rna", "$resource:$geneid-$uniqueID", 0, 0);
		printN3( "$resource:$geneid-$uniqueID", "$rdf#type", "$vocabulary:RNA-ref", 0, 0);
		RNA_ref($_,"$resource:$geneid-$uniqueID");
	}
	if(exists $doc->{'summary'}){
		printN3( "$base:$geneid", "$dc/abstract", $doc->{'summary'}, 1, "^^xsd:string");
	}
	foreach(@{$doc->{'location'}}){
		my $uniqueID = generateUniqueURI($_);
		printN3( "$base:$geneid", "$vocabulary:location", "$resource:$geneid-$uniqueID", 0, 0);
		printN3( "$resource:$geneid-$uniqueID", "$rdf#type", "$vocabulary:Maps", 0, 0);
		Maps($_,"$resource:$geneid-$uniqueID");
	}
	foreach(@{$doc->{'gene-source'}}){
		my $uniqueID = generateUniqueURI($_);
		printN3( "$base:$geneid", "$vocabulary:gene-source", "$resource:$geneid-$uniqueID", 0, 0);
		printN3( "$resource:$geneid-$uniqueID", "$rdf#type", "$vocabulary:Gene-source", 0, 0);
		Gene_source($_,"$resource:$geneid-$uniqueID");
	}
	foreach(@{$doc->{'locus'}}){
		my $uniqueID = generateUniqueURI($_);
		printN3( "$base:$geneid", "$vocabulary:locus", "$resource:$geneid-$uniqueID", 0, 0);
		printN3( "$resource:$geneid-$uniqueID", "$rdf#type", "$vocabulary:Gene-commentary", 0, 0);
		Gene_commentary($_,"$resource:$geneid-$uniqueID");
	}
	foreach(@{$doc->{'properties'}}){
		my $uniqueID = generateUniqueURI($_);
		printN3( "$base:$geneid", "$vocabulary:properties", "$resource:$geneid-$uniqueID", 0, 0);
		printN3( "$resource:$geneid-$uniqueID", "$rdf#type", "$vocabulary:Gene-commentary", 0, 0);
		Gene_commentary($_,"$resource:$geneid-$uniqueID");
	}
	foreach(@{$doc->{'refgene'}}){
		my $uniqueID = generateUniqueURI($_);
		printN3( "$base:$geneid", "$vocabulary:refgene", "$resource:$geneid-$uniqueID", 0, 0);
		printN3( "$resource:$geneid-$uniqueID", "$rdf#type", "$vocabulary:Gene-commentary", 0, 0);
		Gene_commentary($_,"$resource:$geneid-$uniqueID");
	}
	foreach(@{$doc->{'homology'}}){
		my $uniqueID = generateUniqueURI($_);
		printN3( "$base:$geneid", "$vocabulary:homology", "$resource:$geneid-$uniqueID", 0, 0);
		printN3( "$resource:$geneid-$uniqueID", "$rdf#type", "$vocabulary:Gene-commentary", 0, 0);
		Gene_commentary($_,"$resource:$geneid-$uniqueID");
	}
	foreach(@{$doc->{'comments'}}){
		my $uniqueID = generateUniqueURI($_);
		printN3( "$base:$geneid", "$vocabulary:comments", "$resource:$geneid-$uniqueID", 0, 0);
		printN3( "$resource:$geneid-$uniqueID", "$rdf#type", "$vocabulary:Gene-commentary", 0, 0);
		Gene_commentary($_,"$resource:$geneid-$uniqueID");
	}
	foreach(@{$doc->{'unique-keys'}}){
		Dbtag($_,"$base:$geneid","unique-keys");
	}
	foreach(@{$doc->{'xtra-index-terms'}}){
		printN3( "$base:$geneid", "$vocabulary:xtra-index-terms", $_, 1, "^^xsd:string");
	}
	if(exists $doc->{'xtra-properties'}){
		foreach(@{$doc->{'xtra-properties'}}){
			my $uniqueID = generateUniqueURI($_);
			printN3( "$base:$geneid", "$vocabulary:xtra-properties", "$resource:$geneid-$uniqueID", 0, 0);
			printN3( "$resource:$geneid-$uniqueID", "$rdf#type", "$vocabulary:Xtra-Terms", 0, 0);
			Xtra_Terms($_,"$resource:$geneid-$uniqueID");
		}
	}
	if(exists $doc->{'xtra-iq'}){
		foreach(@{$doc->{'xtra-iq'}}){
			my $uniqueID = generateUniqueURI($_);
			printN3( "$base:$geneid", "$vocabulary:xtra-iq", "$resource:$geneid-$uniqueID", 0, 0);
			printN3( "$resource:$geneid-$uniqueID", "$rdf#type", "$vocabulary:Xtra-Terms", 0, 0);
			Xtra_Terms($_,"$resource:$geneid-$uniqueID");
		}
	}
	foreach(@{$doc->{'non-unique-keys'}}){
		Dbtag($_,"$base:$geneid","non-unique-keys");
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/Gene-track.html]
sub Gene_track{
	my $doc = shift;
	my $subject = shift;

	printN3( "$base:$geneid", "$dc/identifier", "geneid:".$doc->{'geneid'}, 1, "^^xsd:string");

	printN3( "$subject", "$vocabulary:geneid", $doc->{'geneid'}, 1, "^^xsd:integer");

	my $replaced_geneid = "no";
	foreach(@{$doc->{'current-id'}}){
		if($_->{'db'} =~ /^GeneID$/){
			$replaced_geneid = $_->{'tag'}->[0]->{'id'};
		}
	}
	if($doc->{'status'} =~ /^secondary$/ && $replaced_geneid !~ /^no$/){
		printN3( "$subject", "$dc/isReplacedBy", "$base:$replaced_geneid", 0, 0);
	}

	if(exists $doc->{'status'}){
		printN3( "$subject", "$vocabulary:status", $doc->{'status'}, 1, "^^xsd:string");
	}
	else{
		printN3( "$subject", "$vocabulary:status", "live", 1, "^^xsd:string");
	}

	if(exists $doc->{'current-id'}){
		foreach(@{$doc->{'current-id'}}){
			Dbtag($_,"$base:$geneid","current-id");
		}
	}

	if(exists $doc->{'create-date'}){
		foreach(@{$doc->{'create-date'}}){
			Date($_,$graph,"$dc/created");
		}
	}

	if(exists $doc->{'update-date'}){
		foreach(@{$doc->{'update-date'}}){
			Date($_,$graph,"$dc/modified");
		}
	}

	if(exists $doc->{'discontinue-date'}){
		foreach(@{$doc->{'discontinue-date'}}){
			Date($_,$graph,"$resource:discontinue-date");
		}
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/Dbtag.html]
sub Dbtag{
	my $doc = shift;
	my $subject = shift;
	my $predicate = shift;
	
	my $xref = "";

	if($doc->{'db'} =~ /MIM/){$xref = "omim";}
	elsif($doc->{'db'} =~ /Evidence/){$xref = "evidence_viewer";}
	elsif($doc->{'db'} =~ /Iowa/){$xref = "pqtldb";}
	elsif($doc->{'db'} =~ /Leiden/){$xref = "lmd";}
	elsif($doc->{'db'} =~ /locus\s{1}tag/){$xref = "locus_tag";}
	elsif($doc->{'db'} =~ /IL2RGbase/){$xref = "il2rgbase";}
	elsif($doc->{'db'} =~ /Steroid/){$xref = "steroid_html";}
	elsif($doc->{'db'} =~ /t1dbase/){$xref = "t1dbase";}
	elsif($doc->{'db'} =~ /hfidb/){$xref = "hfidb";}
	elsif($doc->{'db'} =~ /sickkids/){$xref = "cftr";}
	elsif($doc->{'db'} =~ /UniProtKB/){$xref = "uniprot";}
	else{
		if($xref =~ /^$/){$xref = lc($doc->{'db'});}
	}

	my $id = "";
	if(exists $doc->{'tag'}->[0]->{'id'}){
		$id = $doc->{'tag'}->[0]->{'id'};
	}
	else{
		$id = $doc->{'tag'}->[0]->{'str'};
	}

	printN3( "$subject", "$vocabulary:$predicate", "http://bio2rdf.org/$xref:$id", 0, 0);

	xRef("$xref:$id");
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/Date.html]
sub Date{
	my $doc = shift;
	my $subject = shift;
	my $predicate = shift;

	my $year = $doc->{'std'}->[0]->{'year'};
	my $month = 1;
	exists $doc->{'std'}->[0]->{'month'} ? $month = $doc->{'std'}->[0]->{'month'} : $month = 1;
	my $day = 1;
	exists $doc->{'std'}->[0]->{'day'} ? $day = $doc->{'std'}->[0]->{'day'} : $day = 1;
	my $hour = 0;
	exists $doc->{'std'}->[0]->{'hour'} ? $hour = $doc->{'std'}->[0]->{'hour'} : $hour = 0;
	my $minute = 0;
	exists $doc->{'std'}->[0]->{'minute'} ? $minute = $doc->{'std'}->[0]->{'minute'} : $minute = 0;
	my $second = 0;
	exists $doc->{'std'}->[0]->{'second'} ? $second = $doc->{'std'}->[0]->{'second'} : $second = 0;

	my $yearF = sprintf("%04d",$year);
	my $monthF =  sprintf("%02d",$month);
	my $dayF = sprintf("%02d",$day);
	my $hourF = sprintf("%02d",$hour);
	my $minuteF = sprintf("%02d",$minute);
	my $secondF = sprintf("%02d",$second);
	printN3( "$subject", "$predicate", "$yearF-$monthF-$dayF"."T"."$hourF:$minuteF:$secondF", 1, "^^xsd:dateTime");
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/BioSource.html]
sub BioSource{
	my $doc = shift;
	my $subject = shift;

	if(exists $doc->{'genome'}){
		printN3( "$subject", "$vocabulary:genome",  $doc->{'genome'}, 1, "^^xsd:string");
	}
	else{
		printN3( "$subject", "$vocabulary:genome", "unknown", 1, "^^xsd:string");
	}

	if(exists $doc->{'origin'}){
		printN3( "$subject", "$vocabulary:origin", $doc->{'origin'}, 1, "^^xsd:string");
	}
	else{
		printN3( "$subject", "$vocabulary:origin", "unknown", 1, "^^xsd:string");
	}

	if(exists $doc->{'org'}){
		foreach(@{$doc->{'org'}}){
			Orf_ref($_,$subject);
		}
	}

	if(exists $doc->{'subtype'}){
		foreach(@{$doc->{'subtype'}}){
			my $uniqueID = generateUniqueURI($_);
			printN3( "$subject", "$vocabulary:subType", "$resource:$geneid-$uniqueID", 0, 0);
			printN3( "$resource:$geneid-$uniqueID", "$rdf#type", "$vocabulary:SubSource", 0, 0);
			SubSource($_,"$resource:$geneid-$uniqueID");
		}
	}
###############################################################################################
#
#	I have parse the All_data.asn from NCBI and this pcr-primers case don't occur anywhere.
#	I leave it commented.
#
#	if($doc->{'pcr-primers'} !~ /^$/){
#		foreach(@{$doc->{'pcr-primers'}}){
#			PCRReaction($_,"$subject");
#		}
#	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/Org-ref.html]
sub Orf_ref{
	my $doc = shift;
	my $subject = shift;

	if(exists $doc->{'taxname'}){
		printN3( "$subject", "$vocabulary:taxname", $doc->{'taxname'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'common'}){
		printN3( "$subject", "$vocabulary:common", $doc->{'common'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'mod'}){
		foreach(@{$doc->{'mod'}}){
			printN3( "$subject", "$vocabulary:mod", $_, 1, "^^xsd:string");
		}
	}
	if(exists $doc->{'db'}){
		foreach(@{$doc->{'db'}}){
			Dbtag($_,$subject,'db');
		}
	}
	if(exists $doc->{'syn'}){
		foreach(@{$doc->{'syn'}}){
			printN3( "$subject", "$vocabulary:syn", $_, 1, "^^xsd:string");
		}
	}
	if(exists $doc->{'orgname'}){
		OrgName($doc->{'orgname'}->[0],$subject);
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/OrgName.html]
sub OrgName{
	my $doc = shift;
	my $subject = shift;
	
	my @key = (keys %{$doc->{'name'}->[0]});

	if($key[0] =~ /^binomial$/){
		BinomialOrgName($doc->{'name'}->[0]->{'binomial'}->[0],$subject);
	}
	elsif($key[0] =~ /^virus$/){
		printN3( "$subject", "$vocabulary:virus", $doc->{'name'}->[0]->{'virus'}, 1, "^^xsd:string");
	}
	elsif($key[0] =~ /^hybrid$/){
		foreach(@{$doc->{'name'}->[0]->{'hybrid'}}){
			OrgName($_,$subject);
		}
	}
	elsif($key[0] =~ /^namehybrid$/){BinomialOrgName($doc->{'name'}->[0]->{'namedhybrid'}->[0],$subject);}
	elsif($key[0] =~ /^partial$/){
		foreach(@{$doc->{'name'}->[0]->{'partial'}}){
			PartialOrgName($_,$subject);
		}
	}

	if(exists $doc->{'attrib'}){
		printN3( "$subject", "$vocabulary:attrib", $doc->{'attrib'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'mod'}){
		foreach(@{$doc->{'mod'}}){
			my $uniqueID = generateUniqueURI($_);
			printN3( "$subject", "$vocabulary:mod", "$resource:$geneid-$uniqueID", 0, 0);
			printN3( "$resource:$geneid-$uniqueID", "$rdf#type", "$vocabulary:OrgMod", 0, 0);
			OrgMod($_,"$resource:$geneid-$uniqueID");
		}
	}
	if(exists $doc->{'lineage'}){
		printN3( "$subject", "$vocabulary:lineage", $doc->{'lineage'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'gcode'}){
		printN3( "$subject", "$vocabulary:gcode", $doc->{'gcode'}, 1, "^^xsd:integer");
	}
	if(exists $doc->{'mgcode'}){
		printN3( "$subject", "$vocabulary:mgcode", $doc->{'mgcode'}, 1, "^^xsd:integer");
	}
	if(exists $doc->{'div'}){
		printN3( "$subject", "$vocabulary:div", $doc->{'div'}, 1, "^^xsd:string");
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/BinomialOrgName.html]
sub BinomialOrgName{
	my $doc = shift;
	my $subject = shift;

	if(exists $doc->{'genus'}){
		printN3( "$subject", "$vocabulary:genus", $doc->{'genus'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'species'}){
		printN3( "$subject", "$vocabulary:species", $doc->{'species'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'subspecies'}){
		printN3( "$subject", "$vocabulary:subspecies", $doc->{'subspecies'}, 1, "^^xsd:string");
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/PartialOrgName.html]
# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/TaxElement.html]
sub PartialOrgName{
	my $doc = shift;
	my $subject = shift;

	if(exists $doc->{'fixed-level'}){
		printN3( "$subject", "$vocabulary:fixed-level", $doc->{'fixed-level'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'level'}){
		printN3( "$subject", "$vocabulary:level", $doc->{'level'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'name'}){
		printN3( "$subject", "$vocabulary:name", $doc->{'name'}, 1, "^^xsd:string");
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/OrgMod.html]
sub OrgMod{
	my $doc = shift;
	my $subject = shift;

	if(exists $doc->{'subtype'}){
		printN3( "$subject", "$vocabulary:subtype", $doc->{'subtype'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'subname'}){
		printN3( "$subject", "$vocabulary:subname", $doc->{'subname'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'attrib'}){
		printN3( "$subject", "$vocabulary:attrib", $doc->{'attrib'}, 1, "^^xsd:string");
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/SubSource.html]
sub SubSource{
	my $doc = shift;
	my $subject = shift;

	if(exists $doc->{'subtype'}){
		printN3( "$subject", "$vocabulary:subtype", $doc->{'subtype'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'name'}){
		printN3( "$subject", "$vocabulary:name", $doc->{'name'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'attrib'}){
		printN3( "$subject", "$vocabulary:attrib", $doc->{'attrib'}, 1, "^^xsd:string");
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/Gene-ref.html]
sub Gene_ref{
	my $doc = shift;
	my $subject = shift;

	if(exists $doc->{'locus'}){
		printN3( "$base:$geneid", "$rdfs#label",  $doc->{'locus'}." [geneid:$geneid]", 1, "^^xsd:string");
		printN3( "$subject", "$vocabulary:locus", $doc->{'locus'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'allele'}){
		printN3( "$subject", "$vocabulary:allele", $doc->{'allele'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'desc'}){
		printN3( "$subject", "$dc/description", $doc->{'desc'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'maploc'}){
		printN3( "$subject", "$vocabulary:maploc", $doc->{'maploc'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'db'}){
		foreach(@{$doc->{'db'}}){
			Dbtag($_,$subject,'db');
		}
	}
	if(exists $doc->{'syn'}){
		foreach(@{$doc->{'syn'}}){
			printN3( "$subject", "$vocabulary:syn", $_, 1, "^^xsd:string");
		}
	}
	if(exists $doc->{'locus-tag'}){
		printN3( "$subject", "$vocabulary:locus-tag", $doc->{'locus-tag'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'formal-name'}){
		foreach(@{$doc->{'formal-name'}}){
			Gene_nomenclature($_,$subject);
		}
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/Gene-nomenclature.html]
sub Gene_nomenclature{
	my $doc = shift;
	my $subject = shift;

	if(exists $doc->{'status'}){
		printN3( "$subject", "$vocabulary:status", $doc->{'status'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'symbol'}){
		printN3( "$subject", "$vocabulary:symbol", $doc->{'symbol'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'name'}){
		printN3( "$subject", "$vocabulary:name", $doc->{'name'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'source'}){
		foreach(@{$doc->{'source'}}){
			Dbtag($_,$subject,'source');
		}
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/Prot-ref.html]
sub Prot_ref{
	my $doc = shift;
	my $subject = shift;

	
	if(exists $doc->{'name'}){
		foreach(@{$doc->{'name'}}){
			printN3( "$subject", "$vocabulary:name", $_, 1, "^^xsd:string");
		}
	}
	if(exists $doc->{'desc'}){
		printN3( "$subject", "$dc/description", $doc->{'desc'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'ec'}){
		foreach(@{$doc->{'ec'}}){
			printN3( "$subject", "$vocabulary:ec", $_, 1, "^^xsd:string");
			xRef("ec:".$_);
		}
	}
	if(exists $doc->{'activity'}){
		foreach(@{$doc->{'activity'}}){
			printN3( "$subject", "$vocabulary:activity", $_, 1, "^^xsd:string");
		}
	}
	if(exists $doc->{'db'}){
		foreach(@{$doc->{'db'}}){
			Dbtag($_,$subject,'db');
		}
	}
	if(exists $doc->{'processed'}){
		printN3( "$subject", "$vocabulary:processed", $doc->{'processed'}, 1, "^^xsd:string");
	}
	else{
		printN3( "$subject", "$vocabulary:processed", "not-set", 1, "^^xsd:string");
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/RNA-ref.html]
sub RNA_ref{
	my $doc = shift;
	my $subject = shift;

	if(exists $doc->{'type'}){
		printN3( "$subject", "$vocabulary:type", $doc->{'type'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'ext'}){
		if(exists $doc->{'ext'}->[0]->{'name'}){
			printN3( "$subject", "$vocabulary:name", $doc->{'ext'}->[0]->{'name'}, 1, "^^xsd:string");
		}
		if(exists $doc->{'ext'}->[0]->{'tRNA'}){
			foreach(@{$doc->{'ext'}->[0]->{'tRNA'}}){
				my $uniqueID = generateUniqueURI($_);
				printN3( "$subject", "$vocabulary:tRNA", "$resource:$geneid-$uniqueID", 0, 0);
				printN3( "$resource:$geneid-$uniqueID", "$rdf#type", "$vocabulary:Trna-ext", 0, 0);
				Trna_ext($_,"$resource:$geneid-$uniqueID");
			}
		}
		if(exists $doc->{'ext'}->[0]->{'gen'}){
			foreach(@{$doc->{'ext'}->[0]->{'gen'}}){
				my $uniqueID = generateUniqueURI($_);
				printN3( "$subject", "$vocabulary:gen", "$resource:$geneid-$uniqueID", 0, 0);
				printN3( "$resource:$geneid-$uniqueID", "$rdf#type", "$vocabulary:RNA-gen", 0, 0);
				RNA_gen($_,"$resource:$geneid-$uniqueID");
			}
		}
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/Trna-ext.html]
sub Trna_ext{
	my $doc = shift;
	my $subject = shift;

	if(exists $doc->{'aa'}){
		foreach(@{$doc->{'aa'}}){
			while(my($key, $value) = each(%$_)){
				printN3( "$subject", "$vocabulary:$key", $value, 1, "^^xsd:integer");
			}
		}
	}
	if(exists $doc->{'codon'}){
		foreach(@{$doc->{'codon'}}){
			printN3( "$subject", "$vocabulary:codon", $_, 1, "^^xsd:integer");
		}
	}
	if(exists $doc->{'anticodon'}){
		foreach(@{$doc->{'anticodon'}}){
			my $uniqueID = generateUniqueURI($_);
			printN3( "$subject", "$vocabulary:anticodon", "$resource:$geneid-$uniqueID", 0, 0);
			printN3( "$resource:$geneid-$uniqueID", "$rdf#type", "$vocabulary:Seq-loc", 0, 0);
			Seq_loc($_,"$resource:$geneid-$uniqueID");
		}
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/Seq-loc.html]
sub Seq_loc{
	my $doc = shift;
	my $subject = shift;

	if(exists $doc->{'empty'}){
		foreach(@{$doc->{'empty'}}){
			Seq_id($_,$subject);
		}
	}
	if(exists $doc->{'whole'}){
		foreach(@{$doc->{'whole'}}){
			Seq_id($_,$subject);
		}
	}
	if(exists $doc->{'int'}){
		foreach(@{$doc->{'int'}}){
			Seq_interval($_,$subject);
		}
	}
	if(exists $doc->{'packed-int'}){
		foreach(@{$doc->{'packed-int'}}){
			my $uniqueID = generateUniqueURI($_);
			printN3( "$subject", "$vocabulary:packed-int", "$resource:$geneid-$uniqueID", 0, 0);
			printN3( "$resource:$geneid-$uniqueID", "$rdf#type", "$vocabulary:Packed-seqint", 0, 0);
			Seq_interval($_,"$resource:$geneid-$uniqueID:");
		}
	}
	if(exists $doc->{'pnt'}){
		foreach(@{$doc->{'pnt'}}){
			Seq_point($_,$subject);
		}
	}
	if(exists $doc->{'packed-pnt'}){
		foreach(@{$doc->{'whole'}}){
			my $uniqueID = generateUniqueURI($_);
			printN3( "$subject", "$vocabulary:packed-pnt", "$resource:$geneid-$uniqueID", 0, 0);
			printN3( "$resource:$geneid-$uniqueID", "$rdf#type", "$vocabulary:Packed-seqpnt", 0, 0);
			Seq_point($_,"$resource:$geneid-$uniqueID");
		}
	}
	if(exists $doc->{'mix'}){
		foreach(@{$doc->{'mix'}}){
			my $uniqueID = generateUniqueURI($_);
			printN3( "$subject", "$vocabulary:mix", "$resource:$geneid-$uniqueID", 0, 0);
			printN3( "$resource:$geneid-$uniqueID", "$rdf#type", "$vocabulary:Seq-loc-mix", 0, 0);
			Seq_loc($_,"$resource:$geneid-$uniqueID");
		}
	}
	if(exists $doc->{'equiv'}){
		foreach(@{$doc->{'equiv'}}){
			my $uniqueID = generateUniqueURI($_);
			printN3( "$subject", "$vocabulary:equiv", "$resource:$geneid-$uniqueID", 0, 0);
			printN3( "$resource:$geneid-$uniqueID", "$rdf#type", "$vocabulary:Seq-loc-equiv", 0, 0);
			Seq_loc($_,"$resource:$geneid-$uniqueID");
		}
	}
	if(exists $doc->{'bond'}){
		foreach(@{$doc->{'bond'}}){
			Seq_bond($_,$subject);
		}
	}
	if(exists $doc->{'feat'}){
		foreach(@{$doc->{'feat'}}){
			Feat_id($_,$subject);
		}
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/Seq-id.html]
sub Seq_id{
	my $doc = shift;
	my $subject = shift;

	if(exists $doc->{'local'}){
		foreach(@{$doc->{'local'}}){
			Object_id($_,$subject);
		}
	}
	if(exists $doc->{'gibbsq'}){
		printN3( "$subject", "$vocabulary:gibbsq", $doc->{'gibbsq'}, 1, "^^xsd:integer");
	}
	if(exists $doc->{'gibbmt'}){
		printN3( "$subject", "$vocabulary:gibbmt", $doc->{'gibbmt'}, 1, "^^xsd:integer");
	}
	if(exists $doc->{'giim'}){
		foreach(@{$doc->{'giim'}}){
			Giimport_id($_,$subject);
		}
	}
	if(exists $doc->{'genbank'}){
		foreach(@{$doc->{'genbank'}}){
			Textseq_id($_,$subject,'ncbi');
		}
	}
	if(exists $doc->{'embl'}){
		foreach(@{$doc->{'embl'}}){
			Textseq_id($_,$subject,'embl');
		}
	}
	if(exists $doc->{'pir'}){
		foreach(@{$doc->{'pir'}}){
			Textseq_id($_,$subject,'pir');
		}
	}
	if(exists $doc->{'swissprot'}){
		foreach(@{$doc->{'swissprot'}}){
			Textseq_id($_,$subject,'uniprot');
		}
	}
	if(exists $doc->{'patent'}){
		foreach(@{$doc->{'patent'}}){
			Patent_seq_id($_,$subject);
		}
	}
	if(exists $doc->{'other'}){
		foreach(@{$doc->{'other'}}){
			Textseq_id($_,$subject,'ncbi');
		}
	}
	if(exists $doc->{'general'}){
		foreach(@{$doc->{'general'}}){
			Dtbag($_,$subject,'general');
		}
	}
	if(exists $doc->{'gi'}){
		printN3( "$subject", "$vocabulary:gi", "http://bio2rdf.org/gi:".$doc->{'gi'}, 0, 0);
		xRef("gi:".$doc->{'gi'});
	}
	if(exists $doc->{'ddbj'}){
		foreach(@{$doc->{'ddbj'}}){
			Textseq_id($_,$subject,'ddbj');
		}
	}
	if(exists $doc->{'prf'}){
		foreach(@{$doc->{'prf'}}){
			Textseq_id($_,$subject,'prf');
		}
	}
	if(exists $doc->{'pdb'}){
		foreach(@{$doc->{'pdb'}}){
			PDB_seq_id($_,$subject);
		}
	}
	if(exists $doc->{'tpg'}){
		foreach(@{$doc->{'tpg'}}){
			Textseq_id($_,$subject,'ncbi');
		}
	}
	if(exists $doc->{'tpe'}){
		foreach(@{$doc->{'tpe'}}){
			Textseq_id($_,$subject,'embl');
		}
	}
	if(exists $doc->{'tpd'}){
		foreach(@{$doc->{'tpd'}}){
			Textseq_id($_,$subject,'ddbj');
		}
	}
	if(exists $doc->{'gpipe'}){
		foreach(@{$doc->{'gpipe'}}){
			Textseq_id($_,$subject,'gpipe');
		}
	}
	if(exists $doc->{'named-annot-trak'}){
		foreach(@{$doc->{'named-annot-trak'}}){
			Textseq_id($_,$subject,'inatid');
		}
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/Giimport-id.html]
sub Giimport_id{
	my $doc = shift;
	my $subject = shift;

	if(exists $doc->{'id'}){
		printN3( "$subject", "$vocabulary:id", $doc->{'id'}, 1, "^^xsd:integer");
	}
	if(exists $doc->{'db'}){
		printN3( "$subject", "$vocabulary:db", $doc->{'db'}, 1, "^^xsd:string");
		printN3( "$subject", "$vocabulary:giimport", "http://bio2rdf.org/".$doc->{'db'}.":".$doc->{'id'}, 0, 0);
		xRef($doc->{'db'}.":".$doc->{'id'});
	}
	if(exists $doc->{'release'}){
		printN3( "$subject", "$vocabulary:release", $doc->{'release'}, 1, "^^xsd:string");
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/Object-id.html]
sub Object_id{
	my $doc = shift;
	my $subject = shift;

	if(exists $doc->{'id'}){
		printN3( "$subject", "$vocabulary:id", $doc->{'id'}, 1, "^^xsd:integer");
	}
	if(exists $doc->{'str'}){
		printN3( "$subject", "$vocabulary:str", $doc->{'str'}, 1, "^^xsd:string");
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/Textseq-id.html]
sub Textseq_id{
	my $doc = shift;
	my $subject = shift;
	my $db = shift;

	if(exists $doc->{'name'}){
		printN3( "$subject", "$vocabulary:name", $doc->{'name'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'accession'}){
		printN3( "$subject", "$vocabulary:accession", $doc->{'accession'}, 1, "^^xsd:string");
		printN3( "$subject", "$vocabulary:textseq-id", "http://bio2rdf.org/$db:".$doc->{'accession'}, 0, 0);
		xRef($db.":".$doc->{'accession'});
	}
	if(exists $doc->{'release'}){
		printN3( "$subject", "$vocabulary:release", $doc->{'release'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'version'}){
		printN3( "$subject", "$vocabulary:version", $doc->{'version'}, 1, "^^xsd:integer");
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/Patent-seq-id.html]
# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/Id-pat.html]
sub Patent_seq_id{
	my $doc = shift;
	my $subject = shift;

	if(exists $doc->{'seqid'}){
		printN3( "$subject", "$vocabulary:seqid", $doc->{'seqid'}, 1, "^^xsd:integer");
	}
	if(exists $doc->{'cit'}){
		if(exists $doc->{'cit'}->[0]->{'country'}){
			printN3( "$subject", "$vocabulary:country", $doc->{'cit'}->[0]->{'country'}, 1, "^^xsd:string");
		}
		if(exists $doc->{'cit'}->[0]->{'id'}->[0]->{'number'}){
			printN3( "$subject", "$vocabulary:number", $doc->{'cit'}->[0]->{'id'}->[0]->{'number'}, 1, "^^xsd:string");
			printN3( "$subject", "$vocabulary:patent-seq-id", "http://bio2rdf.org/patent:".$doc->{'cit'}->[0]->{'id'}->[0]->{'number'}, 0, 0);
			xRef("patent:".$doc->{'cit'}->[0]->{'id'}->[0]->{'number'});
		}
		if(exists $doc->{'cit'}->[0]->{'id'}->[0]->{'app-number'}){
			printN3( "$subject", "$vocabulary:app-number", $doc->{'cit'}->[0]->{'id'}->[0]->{'app-number'}, 1, "^^xsd:string");
			printN3( "$subject", "$vocabulary:patent-seq-id", "http://bio2rdf.org/patent:".$doc->{'cit'}->[0]->{'id'}->[0]->{'app-number'}, 0, 0);
			xRef("patent:".$doc->{'cit'}->[0]->{'id'}->[0]->{'app-number'});
		}
		if(exists $doc->{'cit'}->[0]->{'doc-type'}){
			printN3( "$subject", "$vocabulary:doc-type", $doc->{'cit'}->[0]->{'doc-type'}, 1, "^^xsd:string");
		}
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/PDB-seq-id.html]
# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/PDB-mol-id.html]
sub PDB_seq_id{
	my $doc = shift;
	my $subject = shift;

	if(exists $doc->{'mol'}){
		printN3( "$subject", "$vocabulary:mol", $doc->{'mol'}, 1, "^^xsd:string");
		printN3( "$subject", "$vocabulary:pdbRef", "http://bio2rdf.org/pdb:".$doc->{'mol'}, 0, 0);
		xRef("pdb:".$doc->{'mol'});
	}
	if(exists $doc->{'chain'}){
		printN3( "$subject", "$vocabulary:chain", $doc->{'chain'}, 1, "^^xsd:integer");
	}
	if(exists $doc->{'rel'}){
		date($doc->{'rel'}->[0],$subject,'rel');
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/Seq-interval.html]
# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/Na-strand.html]
sub Seq_interval{
	my $doc = shift;
	my $subject = shift;

	if(exists $doc->{'from'}){
		printN3( "$subject", "$vocabulary:from", $doc->{'from'}, 1, "^^xsd:integer");
	}
	if(exists $doc->{'to'}){
		printN3( "$subject", "$vocabulary:to", $doc->{'to'}, 1, "^^xsd:integer");
	}
	if(exists $doc->{'strand'}){
		printN3( "$subject", "$vocabulary:strand", $doc->{'strand'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'id'}){
		foreach(@{$doc->{'id'}}){
			Seq_id($_,$subject);
		}
	}
	if(exists $doc->{'fuzz-from'}){
		foreach(@{$doc->{'fuzz-from'}}){
			Int_fuzz($_,$subject,'from');
		}
	}
	if(exists $doc->{'fuzz-to'}){
		foreach(@{$doc->{'fuzz-to'}}){
			Int_fuzz($_,$subject,'to');
		}
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/Int-fuzz.html]
sub Int_fuzz{
	my $doc = shift;
	my $subject = shift;
	my $info = shift;

	my @key = (keys %{$doc});

	if($key[0] =~ /^p-m$/){
		printN3( "$subject", "$vocabulary:$info/p-m", $doc->{'p-m'}, 1, "^^xsd:integer");
	}
	if($key[0] =~ /^range$/){
		printN3( "$subject", "$vocabulary:$info/range/max", $doc->{'range'}->[0]->{'max'}, 1, "^^xsd:integer");
		printN3( "$subject", "$vocabulary:$info/range/min", $doc->{'range'}->[0]->{'min'}, 1, "^^xsd:integer");
	}
	if($key[0] =~ /^pct$/){
		printN3( "$subject", "$vocabulary:$info/pct", $doc->{'pct'}, 1, "^^xsd:integer");
	}
	if($key[0] =~ /^lim$/){
		printN3( "$subject", "$vocabulary:$info/lim", $doc->{'lim'}, 1, "^^xsd:string");
	}
	if($key[0] =~ /^alt$/){
		foreach(@{$doc->{'alt'}}){
			printN3( "$subject", "$vocabulary:$info/alt", $_, 1, "^^xsd:integer");
		}
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/Seq-point.html]
# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/Na-strand.html]
sub Seq_point{
	my $doc = shift;
	my $subject = shift;

	if(exists $doc->{'point'}){
		printN3( "$subject", "$vocabulary:point", $doc->{'point'}, 1, "^^xsd:integer");
	}
	if(exists $doc->{'strand'}){
		printN3( "$subject", "$vocabulary:strand", $doc->{'strand'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'id'}){
		foreach(@{$doc->{'id'}}){
			Seq_id($_,$subject);
		}
	}
	if(exists $doc->{'fuzz'}){
		foreach(@{$doc->{'fuzz'}}){
			Int_fuzz($_,$subject,'fuzz');
		}
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/Seq-bond.html]
sub Seq_bond{
	my $doc = shift;
	my $subject = shift;

	if(exists $doc->{'a'}){
		foreach(@{$doc->{'a'}}){
			my $uniqueID = generateUniqueURI($_);
			printN3( "$subject", "$vocabulary:bond_A", "$resource:$geneid-$uniqueID", 0, 0);
			printN3( "$resource:$geneid-$uniqueID", "$rdf#type", "$resource:Seq-point", 0, 0);
			Seq_point($_,"$resource:$geneid-$uniqueID");
		}
	}
	if(exists $doc->{'b'}){
		foreach(@{$doc->{'b'}}){
			my $uniqueID = generateUniqueURI($_);
			printN3( "$subject", "$vocabulary:bond_B", "$resource:$geneid-$uniqueID", 0, 0);
			printN3( "$resource:$geneid-$uniqueID", "$rdf#type", "$resource:Seq-point", 0, 0);
			Seq_point($_,"$resource:$geneid-$uniqueID");
		}
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/Feat-id.html]
sub Feat_id{
	my $doc = shift;
	my $subject = shift;

	if(exists $doc->{'gibb'}){
		printN3( "$subject", "$vocabulary:gibb", $doc->{'gibb'}, 1, "^^xsd:integer");
	}
	if(exists $doc->{'giim'}){
		foreach(@{$doc->{'giim'}}){
			Giimport_id($_,$subject);
		}
	}
	if(exists $doc->{'local'}){
		foreach(@{$doc->{'local'}}){
			Object_id($_,$subject);
		}
	}
	if(exists $doc->{'general'}){
		foreach(@{$doc->{'general'}}){
			Dbtag($_,$subject,"general");
		}
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/RNA-gen.html]
sub RNA_gen{
	my $doc = shift;
	my $subject = shift;

	if(exists $doc->{'class'}){
		printN3( "$subject", "$vocabulary:class", $doc->{'class'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'product'}){
		printN3( "$subject", "$vocabulary:product", $doc->{'product'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'quals'}){
		foreach(@{$doc->{'quals'}}){
			my $uniqueID = generateUniqueURI($_);
			printN3( "$subject", "$vocabulary:quals", "$resource:$geneid-$uniqueID", 0, 0);
			printN3( "$resource:$geneid-$uniqueID", "$rdf#type", "$resource:RNA-qual", 0, 0);
			RNA_qual($_,"$resource:$geneid-$uniqueID");
		}
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/RNA-qual.html]
# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/RNA-qual-set.html]
sub RNA_qual{
	my $doc = shift;
	my $subject= shift;

	if(exists $doc->{'qual'}){
		printN3( "$subject", "$vocabulary:qual", $doc->{'qual'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'val'}){
		printN3( "$subject", "$vocabulary:val", $doc->{'val'}, 1, "^^xsd:string");
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/Maps.html]
sub Maps{
	my $doc = shift;
	my $subject = shift;

	if(exists $doc->{'display-str'}){
		printN3( "$subject", "$resource:display-str", $doc->{'display-str'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'method'}){
		foreach(@{$doc->{'method'}}){
			my @key = (keys %{$_});
		        if($key[0] =~ /^proxy$/){
				printN3( "$subject", "$vocabulary:proxy", $_->{'proxy'}, 1, "^^xsd:string");
			}
			if($key[0] =~ /^map-type$/){
				printN3( "$subject", "$vocabulary:map-type", $_->{'map-type'}, 1, "^^xsd:string");
			}
		}
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/Gene-source.html]
sub Gene_source{
	my $doc = shift;
	my $subject = shift;

	if(exists $doc->{'src'}){
		printN3( "$subject", "$vocabulary:src", $doc->{'src'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'src-int'}){
		printN3( "$subject", "$vocabulary:src-int", $doc->{'src-int'}, 1, "^^xsd:integer");
	}
	if(exists $doc->{'src-str1'}){
		printN3( "$subject", "$vocabulary:src-str1", $doc->{'src-str1'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'src-str2'}){
		printN3( "$subject", "$vocabulary:src-str2", $doc->{'src-str2'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'gene-display'}){
		printN3( "$subject", "$vocabulary:gene-display", "TRUE", 1, "^^xsd:boolean");
	}
	else{
		printN3( "$subject", "$vocabulary:gene-display", "FALSE", 1, "^^xsd:boolean");
	}
	if(exists $doc->{'locus-display'}){
		printN3( "$subject", "$vocabulary:locus-display", "TRUE", 1, "^^xsd:boolean");
	}
	else{
		printN3( "$subject", "$vocabulary:locus-display", "FALSE", 1, "^^xsd:boolean");
	}
	if(exists $doc->{'extra-terms'}){
		printN3( "$subject", "$vocabulary:extra-terms", "TRUE", 1, "^^xsd:boolean");
	}
	else{
		printN3( "$subject", "$vocabulary:extra-terms", "FALSE", 1, "^^xsd:boolean");
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/Gene-commentary.html]
sub Gene_commentary{
	my $doc = shift;
	my $subject = shift;

	if(exists $doc->{'type'}){
		printN3( "$subject", "$vocabulary:type", $doc->{'type'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'heading'}){
		printN3( "$subject", "$vocabulary:heading", $doc->{'heading'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'label'}){
		printN3( "$subject", "$rdfs#label", $doc->{'label'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'text'}){
		printN3( "$subject", "$vocabulary:text", $doc->{'text'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'accession'}){
		printN3( "$subject", "$vocabulary:accession", $doc->{'accession'}, 1, "^^xsd:string");
		printN3( "$subject", "$vocabulary:ncbiRef", "http://bio2rdf.org/ncbi:".$doc->{'accession'}, 0, 0);
		xRef("ncbi:".$doc->{'accession'});
	}
	if(exists $doc->{'version'}){
		printN3( "$subject", "$vocabulary:version", $doc->{'version'}, 1, "^^xsd:integer");
	}
	if(exists $doc->{'xtra-properties'}){
		foreach(@{$doc->{'xtra-properties'}}){
			my $uniqueID = generateUniqueURI($_);
			printN3( "$subject", "$vocabulary:xtra-properties", "$resource:$geneid-$uniqueID", 0, 0);
			printN3( "$resource:$geneid-$uniqueID", "$rdf#type", "$vocabulary:Xtra-Terms", 0, 0);
			Xtra_Terms($_,"$resource:$geneid-$uniqueID");
		}
	}
	if(exists $doc->{'refs'}){
		foreach(@{$doc->{'refs'}}){
			my $uniqueID = generateUniqueURI($_);
			printN3( "$subject", "$vocabulary:refs", "$resource:$geneid-$uniqueID", 0, 0);
			printN3( "$resource:$geneid-$uniqueID", "$rdf#type", "$resource:Pub", 0, 0);
			Pub($_,"$resource:$geneid-$uniqueID");
		}
	}
	if(exists $doc->{'source'}){
		foreach(@{$doc->{'source'}}){
			my $uniqueID = generateUniqueURI($_);
			printN3( "$subject", "$vocabulary:source", "$resource:$geneid-$uniqueID", 0, 0);
			printN3( "$resource:$geneid-$uniqueID", "$rdf#type", "$vocabulary:Other-source", 0, 0);
			Other_source($_,"$resource:$geneid-$uniqueID");
		}
	}
	if(exists $doc->{'genomic-coords'}){
		foreach(@{$doc->{'genomic-coords'}}){
			my $uniqueID = generateUniqueURI($_);
			printN3( "$subject", "$vocabulary:genomic-coords", "$resource:$geneid-$uniqueID", 0, 0);
			printN3( "$resource:$geneid-$uniqueID", "$rdf#type", "$vocabulary:Seq-loc", 0, 0);
			Seq_loc($_,"$resource:$geneid-$uniqueID");
		}
	}
	if(exists $doc->{'seqs'}){
		foreach(@{$doc->{'seqs'}}){
			my $uniqueID = generateUniqueURI($_);
			printN3( "$subject", "$vocabulary:seqs", "$resource:$geneid-$uniqueID", 0, 0);
			printN3( "$resource:$geneid-$uniqueID", "$rdf#type", "$vocabulary:Seq-loc", 0, 0);
			Seq_loc($_,"$resource:$geneid-$uniqueID");
		}
	}
	if(exists $doc->{'products'}){
		foreach(@{$doc->{'products'}}){
			my $uniqueID = generateUniqueURI($_);
			printN3( "$subject", "$vocabulary:products", "$resource:$geneid-$uniqueID", 0, 0);
			printN3( "$resource:$geneid-$uniqueID", "$rdf#type", "$vocabulary:Gene-commentary", 0, 0);
			Gene_commentary($_,"$resource:$geneid-$uniqueID");
		}
	}
	if(exists $doc->{'properties'}){
		foreach(@{$doc->{'properties'}}){
			my $uniqueID = generateUniqueURI($_);
			printN3( "$subject", "$vocabulary:properties", "$resource:$geneid-$uniqueID", 0, 0);
			printN3( "$resource:$geneid-$uniqueID", "$rdf#type", "$vocabulary:Gene-commentary", 0, 0);
			Gene_commentary($_,"$resource:$geneid-$uniqueID");
		}
	}
	if(exists $doc->{'comment'}){
		foreach(@{$doc->{'comment'}}){
			my $uniqueID = generateUniqueURI($_);
			printN3( "$subject", "$vocabulary:comment", "$resource:$geneid-$uniqueID", 0, 0);
			printN3( "$resource:$geneid-$uniqueID", "$rdf#type", "$vocabulary:Gene-commentary", 0, 0);
			Gene_commentary($_,"$resource:$geneid-$uniqueID");
		}
	}
	if(exists $doc->{'create-date'}){
		foreach(@{$doc->{'create-date'}}){
			Date($_,$subject,"$dc/created");
		}
	}
	if(exists $doc->{'update-date'}){
		foreach(@{$doc->{'update-date'}}){
			Date($_,$subject,"$dc/modified");
		}
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/Xtra-Terms.html]
sub Xtra_Terms{
	my $doc = shift;
	my $subject = shift;

	if(exists $doc->{'tag'}){
		printN3( "$subject", "$vocabulary:tag", $doc->{'tag'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'value'}){
		printN3( "$subject", "$vocabulary:value", $doc->{'value'}, 1, "^^xsd:string");
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/Pub.html]
sub Pub{
	my $doc = shift;
	my $subject = shift;

	if(exists $doc->{'gen'}){
		foreach(@{$doc->{'gen'}}){
			Cit_gen($_,$subject);
		}
	}
	if(exists $doc->{'sub'}){
		foreach(@{$doc->{'sub'}}){
			Cit_sub($_,$subject);
		}
	}
	if(exists $doc->{'medline'}){
		foreach(@{$doc->{'medline'}}){
			Medline_entry($_,$subject);
		}
	}
	if(exists $doc->{'muid'}){
		printN3( "$subject", "$vocabulary:muid", $doc->{'muid'}, 1, "^^xsd:integer");
		printN3( "$subject", "$vocabulary:medlineRef", "http://bio2rdf.org/medline:".$doc->{'muid'}, 0, 0);
		xRef("medline:".$doc->{'muid'});
	}
	if(exists $doc->{'article'}){
		foreach(@{$doc->{'article'}}){
			Cit_art($_,$subject);
		}
	}
	if(exists $doc->{'journal'}){
		foreach(@{$doc->{'journal'}}){
			Cit_jour($_,$subject);
		}
	}
	if(exists $doc->{'book'}){
		foreach(@{$doc->{'book'}}){
			Cit_book($_,$subject);
		}
	}
	if(exists $doc->{'proc'}){
		foreach(@{$doc->{'proc'}}){
			Cit_proc($_,$subject);
		}
	}
	if(exists $doc->{'patent'}){
		foreach(@{$doc->{'patent'}}){
			Cit_pat($_,$subject);
		}
	}
	if(exists $doc->{'pat-id'}){
		if(exists $doc->{'pat-id'}->[0]->{'country'}){
			printN3( "$subject", "$vocabulary:country", $doc->{'pat-id'}->[0]->{'country'}, 1, "^^xsd:string");
		}
		if(exists $doc->{'pat-id'}->[0]->{'id'}->[0]->{'number'}){
			printN3( "$subject", "$vocabulary:number", $doc->{'pat-id'}->[0]->{'id'}->[0]->{'number'}, 1, "^^xsd:string");
			printN3( "$subject", "$vocabulary:patent-seq-id", "http://bio2rdf.org/patent:".$doc->{'pat-id'}->[0]->{'id'}->[0]->{'number'}, 0, 0);
			xRef("patent:".$doc->{'pat-id'}->[0]->{'id'}->[0]->{'number'});
		}
		if(exists $doc->{'pat-id'}->[0]->{'id'}->[0]->{'app-number'}){
			printN3( "$subject", "$vocabulary:app-number", $doc->{'pat-id'}->[0]->{'id'}->[0]->{'app-number'}, 1, "^^xsd:string");
			printN3( "$subject", "$vocabulary:patent-seq-id", "http://bio2rdf.org/patent:".$doc->{'pat-id'}->[0]->{'id'}->[0]->{'app-number'}, 0, 0);
			xRef("patent:".$doc->{'pat-id'}->[0]->{'id'}->[0]->{'app-number'});
		}
		if(exists $doc->{'pat-id'}->[0]->{'doc-type'}){
			printN3( "$subject", "$vocabulary:doc-type", $doc->{'pat-id'}->[0]->{'doc-type'}, 1, "^^xsd:string");
		}
	}
	if(exists $doc->{'man'}){
		foreach(@{$doc->{'man'}}){
			Cit_let($_,$subject);
		}
	}
	if(exists $doc->{'equiv'}){
		foreach(@{$doc->{'equiv'}}){
			my $uniqueID = generateUniqueURI($_);
			printN3( "$subject", "$vocabulary:equiv", "$resource:$geneid-$uniqueID", 0, 0);
			printN3( "$resource:$geneid-$uniqueID", "$rdf#type", "$vocabulary:Pub", 0, 0);
			Pub($_,"$resource:$geneid-$uniqueID");
		}
	}
	if(exists $doc->{'pmid'}){
		if(ref($doc->{'pmid'}) eq 'ARRAY'){
			foreach(@{$doc->{'pmid'}}){
				printN3( "$subject", "$vocabulary:pmid", $_, 1, "^^xsd:integer");
				printN3( "$subject", "$vocabulary:pubmedRef", "http://bio2rdf.org/pubmed:".$_, 0, 0);
				xRef("pubmed:$_");
			}
		}
		else{
			printN3( "$subject", "$vocabulary:pmid", $doc->{'pmid'}, 1, "^^xsd:integer");
			printN3( "$subject", "$vocabulary:pubmedRef", "http://bio2rdf.org/pubmed:".$doc->{'pmid'}, 0, 0);
			xRef("pubmed:".$doc->{'pmid'});
		}
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/Cit-gen.html]
sub Cit_gen{
	my $doc = shift;
	my $subject = shift;

	if(exists $doc->{'cit'}){
		printN3( "$subject", "$vocabulary:cit", $doc->{'cit'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'authors'}){
		foreach(@{$doc->{'authors'}}){
			Auth_list($_,$subject);
		}
	}
	if(exists $doc->{'muid'}){
		printN3( "$subject", "$vocabulary:muid", $doc->{'muid'}, 1, "^^xsd:integer");
		printN3( "$subject", "$vocabulary:medlineRef", "http://bio2rdf.org/medline:".$doc->{'muid'}, 0, 0);
		xRef("medline:".$doc->{'muid'});
	}
	if(exists $doc->{'journal'}){
		foreach(@{$doc->{'journal'}}){
			Title($_,$subject);
		}
	}
	if(exists $doc->{'volume'}){
		printN3( "$subject", "$vocabulary:volume", $doc->{'volume'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'issue'}){
		printN3( "$subject", "$vocabulary:issue", $doc->{'issue'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'pages'}){
		printN3( "$subject", "$vocabulary:pages", $doc->{'pages'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'date'}){
		foreach(@{$doc->{'date'}}){
			Date($_,$subject,"$vocabulary:date");
		}
	}
	if(exists $doc->{'serial-number'}){
		printN3( "$subject", "$vocabulary:serial-number", $doc->{'serial-number'}, 1, "^^xsd:integer");
	}
	if(exists $doc->{'title'}){
		printN3( "$subject", "$vocabulary:title", $doc->{'title'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'pmid'}){
		printN3( "$subject", "$vocabulary:pmid", $doc->{'pmid'}, 1, "^^xsd:integer");
		printN3( "$subject", "$vocabulary:pubmedRef", "http://bio2rdf.org/pubmed:".$doc->{'pmid'}, 0, 0);
		xRef("pubmed:".$doc->{'pmid'});
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/Auth-list.html]
sub Auth_list{
	my $doc = shift;
	my $subject = shift;

	if(exists $doc->{'names'}){
		if(exists $doc->{'names'}->[0]->{'std'}){
			foreach(@{$doc->{'names'}->[0]->{'std'}}){
				my $uniqueID = generateUniqueURI($_);
				printN3( "$subject", "$vocabulary:std_names", "$resource:$geneid-$uniqueID", 0, 0);
				printN3( "$resource:$geneid-$uniqueID", "$rdf#type", "$vocabulary:Author", 0, 0);
	                        Author($_,$subject);
			}
		}
		if(exists $doc->{'names'}->[0]->{'ml'}){
			foreach(@{$doc->{'names'}->[0]->{'ml'}}){
				printN3( "$subject", "$vocabulary:ml_names", $_->{'ml'}, 1, "^^xsd:string");
			}
		}
		if(exists $doc->{'names'}->[0]->{'str'}){
			foreach(@{$doc->{'names'}->[0]->{'str'}}){
				printN3( "$subject", "$vocabulary:str_names", $_->{'str'}, 1, "^^xsd:string");
			}
		}
	}
	if(exists $doc->{'affil'}){
		foreach(@{$doc->{'affil'}}){
			Affil($_,$subject);
		}
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/Author.html]
sub Author{
	my $doc = shift;
	my $subject = shift;

	if(exists $doc->{'name'}){
		foreach(@{$doc->{'name'}}){
			Person_id($_,$subject);
		}
	}
	if(exists $doc->{'level'}){
		printN3( "$subject", "$vocabulary:level", $doc->{'level'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'role'}){
		printN3( "$subject", "$vocabulary:role", $doc->{'role'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'affil'}){
		foreach(@{$doc->{'affil'}}){
			Affil($_,$subject);
		}
	}
	if(exists $doc->{'is-corr'}){
		printN3( "$subject", "$vocabulary:is-corr", $doc->{'is-corr'}, 1, "^^xsd:boolean");
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/Person-id.html]
# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/Name-std.html]
sub Person_id{
	my $doc = shift;
	my $subject = shift;

	if(exists $doc->{'dbtag'}){
		foreach(@{$doc->{'dbtag'}}){
			Dbtag($_,$subject,'dbtag');
		}
	}
	if(exists $doc->{'name'}){
		foreach(@{$doc->{'name'}}){
			if(exists $_->[0]->{'last'}){
				printN3( "$subject", "$foaf/familyName", $_->[0]->{'last'}, 1, "^^xsd:string");
			}
			if(exists $_->[0]->{'first'}){
				printN3( "$subject", "$foaf/givenName", $_->[0]->{'first'}, 1, "^^xsd:string");
			}
			if(exists $_->[0]->{'middle'}){
				printN3( "$subject", "$vocabulary:middleName", $_->[0]->{'middle'}, 1, "^^xsd:string");
			}
			if(exists $_->[0]->{'full'}){
				printN3( "$subject", "$foaf/name", $_->[0]->{'full'}, 1, "^^xsd:string");
			}
			if(exists $_->[0]->{'initials'}){
				printN3( "$subject", "$vocabulary:initials", $_->[0]->{'initials'}, 1, "^^xsd:string");
			}
			if(exists $_->[0]->{'suffix'}){
				printN3( "$subject", "$vocabulary:suffixName", $_->[0]->{'suffix'}, 1, "^^xsd:string");
			}
			if(exists $_->[0]->{'title'}){
				printN3( "$subject", "$foaf/title", $_->[0]->{'title'}, 1, "^^xsd:string");
			}
		}
	}
	if(exists $doc->{'ml'}){
		printN3( "$subject", "$vocabulary:ml", $doc->{'ml'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'str'}){
		printN3( "$subject", "$vocabulary:str", $doc->{'str'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'consortium'}){
		printN3( "$subject", "$vocabulary:consortium", $doc->{'consortium'}, 1, "^^xsd:string");
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/Affil.html]
sub Affil{
	my $doc = shift;
	my $subject = shift;

	if(exists $doc->{'str'}){
		printN3( "$subject", "$vocabulary:str", $doc->{'str'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'std'}){
		if(exists $doc->{'std'}->[0]->{'affil'}){
			printN3( "$subject", "$vocabulary:affil", $doc->[0]->{'affil'}, 1, "^^xsd:string");
		}
		if(exists $doc->{'std'}->[0]->{'div'}){
			printN3( "$subject", "$vocabulary:div", $doc->[0]->{'div'}, 1, "^^xsd:string");
		}
		if(exists $doc->{'std'}->[0]->{'city'}){
			printN3( "$subject", "$vocabulary:city", $doc->[0]->{'city'}, 1, "^^xsd:string");
		}
		if(exists $doc->{'std'}->[0]->{'sub'}){
			printN3( "$subject", "$vocabulary:sub", $doc->[0]->{'sub'}, 1, "^^xsd:string");
		}
		if(exists $doc->{'std'}->[0]->{'country'}){
			printN3( "$subject", "$vocabulary:country", $doc->[0]->{'country'}, 1, "^^xsd:string");
		}
		if(exists $doc->{'std'}->[0]->{'street'}){
			printN3( "$subject", "$vocabulary:street", $doc->[0]->{'street'}, 1, "^^xsd:string");
		}
		if(exists $doc->{'std'}->[0]->{'email'}){
			printN3( "$subject", "$vocabulary:email", $doc->[0]->{'email'}, 1, "^^xsd:string");
		}
		if(exists $doc->{'std'}->[0]->{'fax'}){
			printN3( "$subject", "$vocabulary:fax", $doc->[0]->{'fax'}, 1, "^^xsd:string");
		}
		if(exists $doc->{'std'}->[0]->{'phone'}){
			printN3( "$subject", "$vocabulary:phone", $doc->[0]->{'phone'}, 1, "^^xsd:string");
		}
		if(exists $doc->{'std'}->[0]->{'postal-code'}){
			printN3( "$subject", "$vocabulary:postal-code", $doc->[0]->{'postal-code'}, 1, "^^xsd:string");
		}
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/Title.html]
sub Title{
	my $doc = shift;
	my $subject = shift;
	
	if(exists $doc->{'name'}){
		printN3( "$subject", "$vocabulary:name", $doc->{'name'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'tsub'}){
		printN3( "$subject", "$vocabulary:tsub", $doc->{'tsub'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'trans'}){
		printN3( "$subject", "$vocabulary:trans", $doc->{'trans'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'jta'}){
		printN3( "$subject", "$vocabulary:jta", $doc->{'jta'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'iso-jta'}){
		printN3( "$subject", "$vocabulary:iso-jta", $doc->{'iso-jta'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'ml-jta'}){
		printN3( "$subject", "$vocabulary:ml-jta", $doc->{'ml-jta'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'coden'}){
		printN3( "$subject", "$vocabulary:coden", $doc->{'coden'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'issn'}){
		printN3( "$subject", "$vocabulary:issn", $doc->{'issn'}, 1, "^^xsd:string");
		printN3( "$subject", "$vocabulary:issnRef", "http://bio2rdf.org/issn:".$doc->{'issn'}, 0, 0);
		xRef("issn:".$doc->{'issn'});
	}
	if(exists $doc->{'abr'}){
		printN3( "$subject", "$vocabulary:abr", $doc->{'abr'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'isbn'}){
		printN3( "$subject", "$vocabulary:isbn", $doc->{'isbn'}, 1, "^^xsd:string");
		printN3( "$subject", "$vocabulary:isbnRef", "http://bio2rdf.org/isbn:".$doc->{'isbn'}, 0, 0);
		xRef("isbn:".$doc->{'isbn'});
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/Cit-sub.html]
sub Cit_sub{
	my $doc = shift;
	my $subject = shift;

	if(exists $doc->{'authors'}){
		foreach(@{$doc->{'authors'}}){
			Auth_list($_,$subject);
		}
	}
	if(exists $doc->{'imp'}){
		foreach(@{$doc->{'imp'}}){
			Imprint($_,$subject);
		}
	}
	if(exists $doc->{'medium'}){
		printN3( "$subject", "$vocabulary:medium", $doc->{'medium'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'date'}){
		foreach(@{$doc->{'date'}}){
			Date($_,$subject,"$vocabulary:date");
		}
	}
	if(exists $doc->{'descr'}){
		printN3( "$subject", "$vocabulary:descr", $doc->{'descr'}, 1, "^^xsd:string");
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/Imprint.html]
# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/CitRetract.html]
# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/PubStatus.html]
sub Imprint{
	my $doc = shift;
	my $subject = shift;

	if(exists $doc->{'date'}){
		foreach(@{$doc->{'date'}}){
			Date($_,$subject,"$vocabulary:date");
		}
	}
	if(exists $doc->{'volume'}){
		printN3( "$subject", "$vocabulary:volume", $doc->{'volume'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'issue'}){
		printN3( "$subject", "$vocabulary:issue", $doc->{'issue'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'pages'}){
		printN3( "$subject", "$vocabulary:pages", $doc->{'pages'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'section'}){
		printN3( "$subject", "$vocabulary:section", $doc->{'section'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'pub'}){
		foreach(@{$doc->{'pub'}}){
			Affil($_,$subject);
		}
	}
	if(exists $doc->{'cprt'}){
		foreach(@{$doc->{'cprt'}}){
			Date($_,$subject,"$vocabulary:cprt");
		}
	}
	if(exists $doc->{'part-sup'}){
		printN3( "$subject", "$vocabulary:part-sup", $doc->{'part-sup'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'language'}){
		printN3( "$subject", "$vocabulary:language", $doc->{'language'}, 1, "^^xsd:string");
	}
	else{
		printN3( "$subject", "$vocabulary:language", "ENG", 1, "^^xsd:string");
	}
	if(exists $doc->{'prepub'}){
		printN3( "$subject", "$vocabulary:prepub", $doc->{'prepub'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'part-supi'}){
		printN3( "$subject", "$vocabulary:part-supi", $doc->{'part-supi'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'retract'}){
		if(exists $doc->{'retract'}->[0]->{'type'}){
			printN3( "$subject", "$vocabulary:retract", $doc->{'retract'}->[0]->{'type'}, 1, "^^xsd:string");
		}
		if(exists $doc->{'retract'}->[0]->{'exp'}){
			printN3( "$subject", "$vocabulary:exp", $doc->{'retract'}->[0]->{'exp'}, 1, "^^xsd:string");
		}
	}
	if(exists $doc->{'pubstatus'}){
		printN3( "$subject", "$vocabulary:pubstatus", $doc->{'pubstatus'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'history'}){
		foreach(@{$doc->{'history'}}){
			my $uniqueID = generateUniqueURI($_);
			printN3( "$subject", "$vocabulary:history", "$resource:$geneid-$uniqueID", 0, 0);
			printN3( "$resource:$geneid-$uniqueID", "$rdf#type", "$vocabulary:PubStatusDate", 0, 0);
			PubStatusDate($_,"$resource:$geneid-$uniqueID");
		}
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/PubStatusDate.html]
# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/PubStatus.html]
sub PubStatusDate{
	my $doc = shift;
	my $subject = shift;

	if(exists $doc->{'pubstatus'}){
		printN3( "$subject", "$vocabulary:pubstatus", $doc->{'pubstatus'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'date'}){
		foreach(@{$doc->{'date'}}){
			Date($_,$subject,"$vocabulary:date");
		}
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/Medline-entry.html]
sub Medline_entry{
	my $doc = shift;
	my $subject = shift;

	if(exists $doc->{'uid'}){
		printN3( "$subject", "$vocabulary:uid", $doc->{'uid'}, 1, "^^xsd:integer");
		printN3( "$subject", "$vocabulary:uidRef", "http://bio2rdf.org/medline:".$doc->{'uid'}, 0, 0);
		xRef("medline:".$doc->{'uid'});
	}
	if(exists $doc->{'em'}){
		foreach(@{$doc->{'em'}}){
			Date($_,$subject,"$vocabulary:em");
		}
	}
	if(exists $doc->{'cit'}){
		foreach(@{$doc->{'cit'}}){
			Cit_art($_,$subject);
		}
	}
	if(exists $doc->{'abstract'}){
		printN3( "$subject", "$dc/abstract", $doc->{'abstract'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'mesh'}){
		foreach(@{$doc->{'mesh'}}){
			my $uniqueID = generateUniqueURI($_);
			printN3( "$subject", "$vocabulary:mesh", "$resource:$geneid-$uniqueID", 0, 0);
			printN3( "$resource:$geneid-$uniqueID", "$rdf#type", "$vocabulary:Medline-mesh", 0, 0);
			Medline_mesh($_,"$resource:$geneid-$uniqueID");
		}
	}
	if(exists $doc->{'substance'}){
		foreach(@{$doc->{'substance'}}){
			my $uniqueID = generateUniqueURI($_);
			printN3( "$subject", "$vocabulary:substance", "$resource:$geneid-$uniqueID", 0, 0);
			printN3( "$resource:$geneid-$uniqueID", "$rdf#type", "$vocabulary:Medline-rn", 0, 0);
			Medline_rn($_,"$resource:$geneid-$uniqueID");
		}
	}
	if(exists $doc->{'xref'}){
		foreach(@{$doc->{'xref'}}){
			my $uniqueID = generateUniqueURI($_);
			printN3( "$subject", "$vocabulary:xref", "$resource:$geneid-$uniqueID", 0, 0);
			printN3( "$resource:$geneid-$uniqueID", "$rdf#type", "$vocabulary:Medline-si", 0, 0);
			Medline_si($_,"$resource:$geneid-$uniqueID");
		}
	}
	if(exists $doc->{'idnum'}){
		foreach(@{$doc->{'idnum'}}){
			printN3( "$subject", "$vocabulary:idnum", $_->{'idnum'}, 1, "^^xsd:string");
		}
	}
	if(exists $doc->{'gene'}){
		foreach(@{$doc->{'gene'}}){
			printN3( "$subject", "$vocabulary:gene", $_->{'activity'}, 1, "^^xsd:string");
		}
	}
	if(exists $doc->{'pmid'}){
		printN3( "$subject", "$vocabulary:pmid", $doc->{'pmid'}, 1, "^^xsd:integer");
		printN3( "$subject", "$vocabulary:pubmedRef", "http://bio2rdf.org/pubmed:$doc->{'pmid'}", 0, 0);
		xRef("pubmed:".$doc->{'pmid'});
	}
	if(exists $doc->{'pub-type'}){
		foreach(@{$doc->{'pub-type'}}){
			printN3( "$subject", "$vocabulary:pub-type", $_->{'pub-type'}, 1, "^^xsd:string");
		}
	}
	if(exists $doc->{'mlfield'}){
		foreach(@{$doc->{'mlfield'}}){
			my $uniqueID = generateUniqueURI($_);
			printN3( "$subject", "$vocabulary:mlfield", "$resource:$geneid-$uniqueID", 0, 0);
			printN3( "$resource:$geneid-$uniqueID", "$rdf#type", "$vocabulary:Medline-field", 0, 0);
			Medline_field($_,"$resource:$geneid-$uniqueID");
		}
	}
	if(exists $doc->{'status'}){
		printN3( "$subject", "$vocabulary:status", $doc->{'status'}, 1, "^^xsd:string");
	}
	else{
		printN3( "$subject", "$vocabulary:status", "medline", 1, "^^xsd:string");
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/Cit-art.html]
sub Cit_art{
	my $doc = shift;
	my $subject = shift;

	if(exists $doc->{'title'}){
		foreach(@{$doc->{'title'}}){
			Title($_,$subject);
		}
	}
	if(exists $doc->{'authors'}){
		foreach(@{$doc->{'authors'}}){
			Auth_list($_,$subject);
		}
	}
	if(exists $doc->{'from'}){
		if(exists $doc->{'from'}->[0]->{'journal'}){
			Cit_jour($_,$subject);
		}
		if(exists $doc->{'from'}->[0]->{'book'}){
			Cit_book($_,$subject);
		}
		if(exists $doc->{'from'}->[0]->{'proc'}){
			Cit_proc($_,$subject);
		}
	}
	if(exists $doc->{'ids'}){
		foreach(@{$doc->{'ids'}}){
			ArticleId($_,$subject);
		}
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/ArticleId.html]
# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/PubMedId.html]
# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/MedlineUID.html]
# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/DOI.html]
# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/PII.html]
# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/PmcID.html]
# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/PmcPid.html]
# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/PmPid.html]
sub ArticleId{
	my $doc = shift;
	my $subject = shift;

	if(exists $doc->{'pubmed'}){
		printN3( "$subject", "$vocabulary:pubmed", $doc->{'pubmed'}, 1, "^^xsd:integer");
		printN3( "$subject", "$vocabulary:pubmedRef", "http://bio2rdf.org/pubmed:".$doc->{'pubmed'}, 0, 0);
		xRef("pubmed:".$doc->{'pubmed'});
	}
	if(exists $doc->{'medline'}){
		printN3( "$subject", "$vocabulary:medline", $doc->{'medline'}, 1, "^^xsd:integer");
		printN3( "$subject", "$vocabulary:medlineRef", "http://bio2rdf.org/medline:".$doc->{'medline'}, 0, 0);
		xRef("medline:".$doc->{'medline'});
	}
	if(exists $doc->{'doi'}){
		printN3( "$subject", "$vocabulary:doi", $doc->{'doi'}, 1, "^^xsd:string");
		printN3( "$subject", "$vocabulary:doiRef", "http://bio2rdf.org/doi:".$doc->{'doi'}, 0, 0);
		xRef("doi:".$doc->{'doi'});
	}
	if(exists $doc->{'pii'}){
		printN3( "$subject", "$vocabulary:pii", $doc->{'pii'}, 1, "^^xsd:string");
		printN3( "$subject", "$vocabulary:piiRef", "http://bio2rdf.org/pii:".$doc->{'pii'}, 0, 0);
		xRef("pii:".$doc->{'pii'});
	}
	if(exists $doc->{'pmcid'}){
		printN3( "$subject", "$vocabulary:pmcid", $doc->{'pmcid'}, 1, "^^xsd:integer");
		printN3( "$subject", "$vocabulary:pmcidRef", "http://bio2rdf.org/pmcid:".$doc->{'pmcid'}, 0, 0);
		xRef("pmcid:".$doc->{'pmcid'});
	}
	if(exists $doc->{'pmcpid'}){
		printN3( "$subject", "$vocabulary:pmcpid", $doc->{'pmcpid'}, 1, "^^xsd:string");
		printN3( "$subject", "$vocabulary:pmcpidRef", "http://bio2rdf.org/pmcpid:".$doc->{'pmcpid'}, 0, 0);
		xRef("pmcpid:".$doc->{'pmcpid'});
	}
	if(exists $doc->{'pmpid'}){
		printN3( "$subject", "$vocabulary:pmpid", $doc->{'pmpid'}, 1, "^^xsd:string");
		printN3( "$subject", "$vocabulary:pmpid", "http://bio2rdf.org/pmpid:".$doc->{'pmpid'}, 0, 0);
		xRef("pmpid:".$doc->{'pmpid'});
	}
	if(exists $doc->{'other'}){
		foreach(@{$doc->{'other'}}){
			Dbtag($_,$subject,"other");
		}
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/Cit-jour.html]
sub Cit_jour{
	my $doc = shift;
	my $subject = shift;

	if(exists $doc->{'title'}){
		foreach(@{$doc->{'title'}}){
			Title($_,$subject);
		}
	}
	if(exists $doc->{'imp'}){
		foreach(@{$doc->{'imp'}}){
			Imprint($_,$subject);
		}
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/Cit-book.html]
sub Cit_book{
	my $doc = shift;
	my $subject = shift;

	if(exists $doc->{'title'}){
		foreach(@{$doc->{'title'}}){
			Title($_,$subject);
		}
	}
	if(exists $doc->{'coll'}){
		foreach(@{$doc->{'coll'}}){
			Title($_,$subject);
		}
	}
	if(exists $doc->{'authors'}){
		foreach(@{$doc->{'authors'}}){
			Auth_list($_,$subject);
		}
	}
	if(exists $doc->{'imp'}){
		foreach(@{$doc->{'imp'}}){
			Imprint($_,$subject);
		}
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/Cit-proc.html]
sub Cit_proc{
	my $doc = shift;
	my $subject = shift;

	if(exists $doc->{'book'}){
		Cit_book($_,$subject);
	}
	if(exists $doc->{'meet'}){
		Meeting($_,$subject);
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/Meeting.html]
sub Meeting{
	my $doc = shift;
	my $subject = shift;

	if(exists $doc->{'number'}){
		printN3( "$subject", "$vocabulary:number", $doc->{'number'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'em'}){
		foreach(@{$doc->{'em'}}){
			Date($_,$subject,"$vocabulary:em");
		}
	}
	if(exists $doc->{'place'}){
		foreach(@{$doc->{'place'}}){
			Affil($_,$subject);
		}
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/Medline-mesh.html]
sub Medline_mesh{
	my $doc = shift;
	my $subject = shift;

	if(exists $doc->{'mp'}){
		printN3( "$subject", "$vocabulary:mp", $doc->{'mp'}, 1, "^^xsd:boolean");
	}
	else{
		printN3( "$subject", "$vocabulary:mp", "FALSE", 1, "^^xsd:boolean");
	}
	if(exists $doc->{'term'}){
		printN3( "$subject", "$vocabulary:term", $doc->{'term'}, 1, "^^xsd:string");
		my $term = $doc->{'term'};
		$term =~ s/ /_/g;
		printN3( "$subject", "$vocabulary:meshTerm", "http://bio2rdf.org/mesh:$term", 0, 0);
		xRef("mesh:$term");
	}
	if(exists $doc->{'qual'}){
		foreach(@{$doc->{'qual'}}){
			my $uniqueID = generateUniqueURI($_);
			printN3( "$subject", "$vocabulary:qual", "$resource:$geneid-$uniqueID", 0, 0);
			printN3( "$resource:$geneid-$uniqueID", "$rdf#type", "$vocabulary:Medline-qual", 0, 0);
			Medline_qual($_,"$resource:$geneid-$uniqueID");
		}
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/Medline-qual.html]
sub Medline_qual{
	my $doc = shift;
	my $subject = shift;
	
	if(exists $doc->{'mp'}){
		printN3( "$subject", "$vocabulary:mp", $doc->{'mp'}, 1, "^^xsd:boolean");
	}
	else{
		printN3( "$subject", "$vocabulary:mp", "FALSE", 1, "^^xsd:boolean");
	}
	if(exists $doc->{'subh'}){
		printN3( "$subject", "$vocabulary:subh", $doc->{'subh'}, 1, "^^xsd:string");
		my $subh = $doc->{'subh'};
		$subh =~ s/ /_/g;
		printN3( "$subject", "$vocabulary:meshSubHeading", "http://bio2rdf.org/mesh:$subh", 0, 0);
		xRef("mesh:$subh");
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/Medline-rn.html]
sub Medline_rn{
	my $doc = shift;
	my $subject = shift;

	if(exists $doc->{'type'}){
		printN3( "$subject", "$vocabulary:type", $doc->{'type'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'cit'}){
		printN3( "$subject", "$vocabulary:cit", $doc->{'cit'}, 1, "^^xsd:string");
		if($doc->{'type'} =~ /cas/){
			printN3( "$subject", "$vocabulary:casRef", "http://bio2rdf.org/cas:".$doc->{'cit'}, 0, 0);
			xRef("cas:".$doc->{'cit'});
		}
		if($doc->{'type'} =~ /ec/){
			printN3( "$subject", "$vocabulary:ecRef", "http://bio2rdf.org/ec:".$doc->{'cit'}, 0, 0);
			xRef("ec:".$doc->{'cit'});
		}
	}
	if(exists $doc->{'name'}){
		printN3( "$subject", "$vocabulary:name", $doc->{'name'}, 1, "^^xsd:string");
	}
	
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/Medline-si.html]
sub Medline_si{
	my $doc = shift;
	my $subject = shift;

	if(exists $doc->{'type'}){
		printN3( "$subject", "$vocabulary:type", $doc->{'type'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'cit'}){
		printN3( "$subject", "$vocabulary:cit", $doc->{'cit'}, 1, "^^xsd:string");
		if($doc->{'type'} =~ /ddbj/){
			printN3( "$subject", "$vocabulary:ddbjRef", "http://bio2rdf.org/ddbj:".$doc->{'cit'}, 0, 0);
			xRef("ddbj:".$doc->{'cit'});
		}
		if($doc->{'type'} =~ /carbbank/){
			printN3( "$subject", "$vocabulary:carbbankRef", "http://bio2rdf.org/carbbank:".$doc->{'cit'}, 0, 0);
			xRef("carbbank:".$doc->{'cit'});
		}
		if($doc->{'type'} =~ /embl/){
			printN3( "$subject", "$vocabulary:emblRef", "http://bio2rdf.org/embl:".$doc->{'cit'}, 0, 0);
			xRef("embl:".$doc->{'cit'});
		}
		if($doc->{'type'} =~ /hdb/){
			printN3( "$subject", "$vocabulary:hdbRef", "http://bio2rdf.org/hdb:".$doc->{'cit'}, 0, 0);
			xRef("hdb:".$doc->{'cit'});
		}
		if($doc->{'type'} =~ /genbank/){
			printN3( "$subject", "$vocabulary:genbankRef", "http://bio2rdf.org/ncbi:".$doc->{'cit'}, 0, 0);
			xRef("ncbi:".$doc->{'cit'});
		}
		if($doc->{'type'} =~ /hgml/){
			printN3( "$subject", "$vocabulary:hgmlRef", "http://bio2rdf.org/hgml:".$doc->{'cit'}, 0, 0);
			xRef("hgml:".$doc->{'cit'});
		}
		if($doc->{'type'} =~ /mim/){
			printN3( "$subject", "$vocabulary:omimRef", "http://bio2rdf.org/omim:".$doc->{'cit'}, 0, 0);
			xRef("omim:".$doc->{'cit'});
		}
		if($doc->{'type'} =~ /msd/){
			printN3( "$subject", "$vocabulary:msdRef", "http://bio2rdf.org/msd:".$doc->{'cit'}, 0, 0);
			xRef("msd:".$doc->{'cit'});
		}
		if($doc->{'type'} =~ /pdb/){
			printN3( "$subject", "$vocabulary:pdbRef", "http://bio2rdf.org/pdb:".$doc->{'cit'}, 0, 0);
			xRef("pdb:".$doc->{'cit'});
		}
		if($doc->{'type'} =~ /pir/){
			printN3( "$subject", "$vocabulary:pirRef", "http://bio2rdf.org/pir:".$doc->{'cit'}, 0, 0);
			xRef("pir:".$doc->{'cit'});
		}
		if($doc->{'type'} =~ /prfseqdb/){
			printN3( "$subject", "$vocabulary:prfseqdbRef", "http://bio2rdf.org/prfseqdb:".$doc->{'cit'}, 0, 0);
			xRef("prfseqdb:".$doc->{'cit'});
		}
		if($doc->{'type'} =~ /psd/){
			printN3( "$subject", "$vocabulary:psdRef", "http://bio2rdf.org/psd:".$doc->{'cit'}, 0, 0);
			xRef("psd:".$doc->{'cit'});
		}
		if($doc->{'type'} =~ /swissprot/){
			printN3( "$subject", "$vocabulary:uniprotRef", "http://bio2rdf.org/uniprot:".$doc->{'cit'}, 0, 0);
			xRef("uniprot:".$doc->{'cit'});
		}
		if($doc->{'type'} =~ /gdb/){
			printN3( "$subject", "$vocabulary:gdbRef", "http://bio2rdf.org/gdb:".$doc->{'cit'}, 0, 0);
			xRef("gdb:".$doc->{'cit'});
		}
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/Medline-field.html]
sub Medline_field{
	my $doc = shift;
	my $subject = shift;
	
	if(exists $doc->{'type'}){
		printN3( "$subject", "$vocabulary:type", $doc->{'type'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'str'}){
		printN3( "$subject", "$vocabulary:str", $doc->{'str'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'ids'}){
		foreach(@{$doc->{'ids'}}){
			my $uniqueID = generateUniqueURI($_);
			printN3( "$subject", "$vocabulary:ids", "$resource:$geneid-$uniqueID", 0, 0);
			printN3( "$resource:$geneid-$uniqueID", "$rdf#type", "$vocabulary:DocRef", 0, 0);
			DocRef($_,"$resource:$geneid-$uniqueID");
		}
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/DocRef.html]
sub DocRef{
	my $doc = shift;
	my $subject = shift;

	if(exists $doc->{'type'}){
		printN3( "$subject", "$vocabulary:type", $doc->{'type'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'uid'}){
		printN3( "$subject", "$vocabulary:uid", $doc->{'uid'}, 1, "^^xsd:integer");
		if($doc->{'type'} =~ /medline/){
			printN3( "$subject", "$vocabulary:medlineRef", "http://bio2rdf.org/medline:".$doc->{'uid'}, 0, 0);
			xRef("medline:".$doc->{'uid'});
		}
		if($doc->{'type'} =~ /pubmed/){
			printN3( "$subject", "$vocabulary:pubmedRef", "http://bio2rdf.org/pubmed:".$doc->{'uid'}, 0, 0);
			xRef("pubmed:".$doc->{'uid'});
		}
		if($doc->{'type'} =~ /ncbigi/){
			printN3( "$subject", "$vocabulary:giRef", "http://bio2rdf.org/gi:".$doc->{'uid'}, 0, 0);
			xRef("gi:".$doc->{'uid'});
		}
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/Cit-pat.html]
sub Cit_pat{
	my $doc = shift;
	my $subject = shift;

	if(exists $doc->{'title'}){
		printN3( "$subject", "$vocabulary:title", $doc->{'title'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'authors'}){
		foreach(@{$doc->{'authors'}}){
			Auth_list($_,$subject);
		}
	}
	if(exists $doc->{'country'}){
		printN3( "$subject", "$vocabulary:country", $doc->{'country'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'doc-type'}){
		printN3( "$subject", "$vocabulary:doc-type", $doc->{'doc-type'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'number'}){
		printN3( "$subject", "$vocabulary:number", $doc->{'number'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'date-issue'}){
		foreach(@{$doc->{'date-issue'}}){
			Date($_,$subject,"$vocabulary:date-issue");
		}
	}
	if(exists $doc->{'class'}){
		foreach(@{$doc->{'class'}}){
			printN3( "$subject", "$vocabulary:class", $_->{'class'}, 1, "^^xsd:string");
		}
	}
	if(exists $doc->{'app-number'}){
		printN3( "$subject", "$vocabulary:app-number", $doc->{'app-number'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'app-date'}){
		foreach(@{$doc->{'app-date'}}){
			Date($_,$subject,"$vocabulary:app-date");
		}
	}
	if(exists $doc->{'appplicants'}){
		foreach(@{$doc->{'applicants'}}){
			Auth_list($_,$subject);
		}
	}
	if(exists $doc->{'assignees'}){
		foreach(@{$doc->{'assignees'}}){
			Auth_list($_,$subject);
		}
	}
	if(exists $doc->{'priority'}){
		foreach(@{$doc->{'priority'}}){
			my $uniqueID = generateUniqueURI($_);
			printN3( "$subject", "$vocabulary:priority", "$resource:$geneid-$uniqueID", 0, 0);
			printN3( "$resource:$geneid-$uniqueID", "$rdf#type", "$vocabulary:Patent-priority", 0, 0);
			Patent_priority($_,"$resource:$geneid-$uniqueID");
		}
	}
	if(exists $doc->{'abstract'}){
		printN3( "$subject", "$dc/abstract", $doc->{'abstract'}, 1, "^^xsd:string");
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/Patent-priority.html]
sub Patent_priority{
	my $doc = shift;
	my $subject = shift;

	if(exists $doc->{'country'}){
		printN3( "$subject", "$vocabulary:country", $doc->{'country'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'number'}){
		printN3( "$subject", "$vocabulary:number", $doc->{'number'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'date'}){
		foreach(@{$doc->{'date'}}){
			Date($_,$subject,"$vocabulary:date");
		}
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/Cit-let.html]
sub Cit_let{
	my $doc = shift;
	my $subject = shift;

	if(exists $doc->{'cit'}){
		foreach(@{$doc->{'cit'}}){
			Cit_book($_,$subject);
		}
	}
	if(exists $doc->{'man-id'}){
		printN3( "$subject", "$vocabulary:man-id", $doc->{'man-id'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'type'}){
		printN3( "$subject", "$vocabulary:type", $doc->{'type'}, 1, "^^xsd:string");
	}
}

# [http://www.ncbi.nlm.nih.gov/IEB/ToolBox/CPP_DOC/asn_spec/Other-source.html]
sub Other_source{
	my $doc = shift;
	my $subject = shift;

	if(exists $doc->{'src'}){
		foreach(@{$doc->{'src'}}){
			Dbtag($_,"$base:$geneid","src");
		}
	}
	if(exists $doc->{'pre-text'}){
		printN3( "$subject", "$vocabulary:pre-text", $doc->{'pre-text'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'anchor'}){
		printN3( "$subject", "$vocabulary:anchor", $doc->{'anchor'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'url'}){
		printN3( "$subject", "$vocabulary:url", $doc->{'url'}, 1, "^^xsd:string");
	}
	if(exists $doc->{'post-text'}){
		printN3( "$subject", "$vocabulary:post-text", $doc->{'post-text'}, 1, "^^xsd:string");
	}
}

# This sub will create a xRef triple with the graph has its subject. This enable to have a quick picture 
# of all the linkout of a specific Entrez Gene record without having to look for all of it in the
# different structure and sub-structure of the document
sub xRef{
	my $smallURI = shift;

	printN3( $graph, "$vocabulary:xRef", "http://bio2rdf.org/$smallURI", 0, 0);
}

# Generate a unique identifier from the content of a node. This have the advantage that it will stay the same
# whenever I rerun the nquadizer unless a change actually happend in the node data. Those are for the made up
# URI use for sub-structure with undertermined number of items.
sub generateUniqueURI{
	my $doc = shift;

	my $dump = Data::Dumper->new([$doc]);
	$dump->Indent(0);

	my $ctx = Digest::MD5->new;
	$ctx->add($dump->Dump);

	return $ctx->hexdigest;
}

# Function that output the quads to the standard output.
# Was placed separately to simplify the addition of modification like the removal of " in a literal in a single place
sub printN3{
	my $subject = shift;
	my $object = shift;
	my $predicate = shift;
	my $literal = shift;
	my $type = shift;

	if($predicate !~ /^$/){
		if($literal){
			$predicate =~ s/"/\u0022/g;
			$predicate =~ s/'/\u0027/g;
			print "<$subject> <$object> ".'"'.$predicate.'"'."$type .\n";
		}
		else{
			print "<$subject> <$object> <$predicate> .\n";
		}
	}
}
