#!/usr/bin/perl -w

# Copyright 2013-2014 André Hentschel
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA

use warnings;
use strict;

use DBI;

our ($db_host, $db_name, $db_user_name, $db_pw, %donealready);
require 'dbsettings.pl';

if (!open(FILEO,">appdbbugzilla.html")) {
    print STDERR "error: unable to open appdbbugzilla.html for writing:\n";
    print STDERR "       $!\n";
    return;
}

print FILEO "<html><head><title>bug links</title></head><body>\n";

my $dbh1 = DBI->connect('DBI:mysql:' . $db_name . ';' . $db_host, $db_user_name, $db_pw) || die "Could not connect to database: $DBI::errstr";

my $sth1 = $dbh1->prepare('SELECT appId, appName FROM appFamily;');
$sth1->execute();

my $row;
my $row2;
my $i=0;
my $once=0;
while ($row = $sth1->fetchrow_arrayref()) {
    my $searchid = @$row[0];
    my $searchfor = @$row[1];
    $searchfor=~s/\\\'/\'/g;
    $searchfor=~s/\'/\\\'/g;
    if (length($searchfor) < 4) {next;}
    $once=0;
    #if ($i>=5) {last;}
    my $sth2 = $dbh1->prepare('SELECT bug_id, short_desc FROM bugs WHERE short_desc LIKE \'%' . $searchfor . '%\' AND bug_status != \'CLOSED\';');
    $sth2->execute();
    while ($row2 = $sth2->fetchrow_arrayref()) {
        my $sth3 = $dbh1->prepare('SELECT v.appId FROM buglinks b, appVersion v WHERE b.bug_id = ' . @$row2[0] . ' AND v.versionId = b.versionId AND v.appId = ' . $searchid . ';');
        $sth3->execute();
        if ($sth3->rows != 0) {next;}

        if ($once == 0) {
            print FILEO "\n<h2><a href=\"https://appdb.winehq.org/objectManager.php?sClass=application&iId=$searchid\">$searchfor:</h2>";
            $once=1;
        }

        $i=$i+1;

        my $bugsummary = @$row2[1];
        $bugsummary=~s/\'/\&prime;/g;
        $bugsummary=~s/\"/\&quot;/g;
        print FILEO "<a href=\"https://bugs.winehq.org/show_bug.cgi?id=@$row2[0]\" title=\"" . $bugsummary . "\">@$row2[0]</a>, ";
    }
    $sth2->finish();
}
printf "$i\n";

$sth1->finish();
$dbh1->disconnect();
print FILEO "\n</body></html>\n";
close(FILEO);
