#!/usr/bin/perl -w
# e.g. perl gennews.pl wwn/kcstats378.txt 10/24/2014 378
use strict;
use File::Copy qw(copy);

my ( $kcstat ) = @ARGV;

my $kcpath;
if ($kcstat =~ /(.*)kcstats/) {
    $kcpath = $1;
}

mkdir $kcpath . "en";
mkdir $kcpath . "de";

my @month_name_en = qw(failure January February March April May June July August September October November December);
my @month_name_de = qw(failure Januar Februar März April Mai Juni Juli August September Oktober November Dezember);

my $filename;
my $newsen;
my $newsde;
my @titles;
my $titlenr = 0;
my $year = 0;
my $month = 0;
my $day = 0;
my $wwn = 0;

open(I, "<$kcstat");
while ($_ = <I>) {
    if (/<issue num=\"([0-9]+)\" date=\"([0-9]+)\/([0-9]+)\/([0-9]+)\"/) {
        #print "wwn $1 date $4 $2 $3\n";
        $filename = $kcpath . "wn$4$2$3_$1";
        $newsen = $kcpath . "en/$4$2$3" . "01.xml";
        $newsde = $kcpath . "de/$4$2$3" . "01.xml";
        $year = $4;
        $month = $2;
        $day = $3;
        $wwn = $1;
        print "fn $filename\n";
        print "fn $newsen\n";
        print "fn $newsde\n";
    }
    if (/title=\"(.*)\"/) {
        $titles[$titlenr++] = $1;
        print "Titel $1\n";
    }
}
close I;

open(Oen, ">$newsen");
print Oen "<news>\n";
print Oen "  <date>$month_name_en[$month] $day, $year</date>\n";
print Oen "  <title>World Wine News Issue $wwn</title>\n";
print Oen "  <body>\n";
print Oen "<a href=\"\{\$root\}/wwn/$wwn\">WWN Issue $wwn</a> was released today.\n";
print Oen "<ul>\n";
foreach my $title (@titles) {
    print Oen "<li><a href=\"\{\$root\}/wwn/$wwn#$title\">$title</a></li>\n";
}
print Oen "</ul>\n";
print Oen "  </body>\n";
print Oen "</news>\n";
close Oen;

open(Ode, ">$newsde");
print Ode "<news>\n";
print Ode "  <date>$day. $month_name_de[$month] $year</date>\n";
print Ode "  <title>World Wine News Ausgabe $wwn</title>\n";
print Ode "  <body>\n";
print Ode "<a href=\"\{\$root\}/wwn/$wwn\">WWN Ausgabe $wwn</a> wurde heute veröffentlicht.\n";
print Ode "<ul>\n";
foreach my $title (@titles) {
    my $transl = $title;
    $transl =~ s/AppDB\/Bugzilla Status Changes/AppDB\/Bugzilla Statusänderungen/;
    $transl =~ s/Weekly/Wöchentliche/;
    print Ode "<li><a href=\"\{\$root\}/wwn/$wwn#$title\">$transl</a></li>\n";
}
print Ode "</ul>\n";
print Ode "  </body>\n";
print Ode "</news>\n";
close Ode;
