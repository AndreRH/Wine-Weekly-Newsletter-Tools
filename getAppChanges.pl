#!/usr/bin/perl -w
# e.g. perl getAppChanges.pl 2014-02-14 2014-03-03 364 > appdb.txt
use strict;

my ( $fromdate, $todate, $WWN) = @ARGV;

our ($db_user_name, $db_pw, %donealready);

require 'dbsettings.pl';

my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime(time);
$year += 1900;
$mon++;
if ( $mday < 10 ) {
    $mday = "0" . $mday;
}
if ( $mon < 10 ) {
    $mon = "0" . $mon;
}
my $file = $year . "$mon" . $mday . ".tar.gz";

if ( !-f "appdb/wine-appdb-$file" ) {
    #print "Downloading new DB file...\n";
    `wget -c -O appdb/wine-appdb-$file ftp://ftp.winehq.org/pub/wine/wine-appdb-$file `;

    #print "Extracting file...\n";
    `cd appdb && tar -xzf wine-appdb-$file`;

    #print "Wiping old database...\n";
    `mysql -u $db_user_name -p -D appdb < truncateall.sql`;

    #print "Inserting file into DB\n";
    `cd appdb && mysql -u $db_user_name -p -D appdb < appdb.sql`;
}

my $from = $fromdate;
$from =~ s/ 00:00:00//;
my $to = $todate;
$to =~ s/ 00:00:00//;

print qq~
<section
        title="Weekly AppDB/Bugzilla Status Changes"
        subject="AppDB/Bugzilla"
        archive="http://appdb.winehq.org"
        posts="0"
>
<topic>AppDB / Bugzilla</topic>
<center><b>Bugzilla Changes:</b></center>
<p>
<center>
<table border="1" bordercolor="#222222" cellspacing="0" cellpadding="3">
  <tr>
  <td align="center">
        <b>Category</b>
  </td>
  <td>
         <b>Total Bugs Last Issue</b>
  </td>
  <td>
        <b>Total Bugs This Issue</b>
  </td>
  <td>
        <b>Net Change</b>
  </td>
  </tr>
~;
my @fromdata = split(/\n/,`perl getBugzillaStats.pl from$WWN $from`);
my @todata = split(/\n/,`perl getBugzillaStats.pl to$WWN Now`);
my $lwwn = $WWN-1;
my @lastdata = split(/\n/,`perl getBugzillaStats.pl to$lwwn`);
my ($ototal,$total,$dtotal,$oOpenTotal,$nOpenTotal);

foreach ( 1 .. $#fromdata ) {
    $fromdata[$_] =~ s/[\n\r"]//g;
    $todata[$_]   =~ s/[\n\r]//;
    my @partsfrom = split( /,/, $fromdata[$_] );
    my @partsto   = split( /,/, $todata[$_] );
    my @partslast = split( /,/, $lastdata[$_] );

    my $netchange = $partsto[1] - $partslast[1];
    my $changed = $partsto[1] - $partsfrom[1];
    my $added = $changed + $netchange;
    $ototal += $partslast[1];
    $total  += $partsto[1];
    $dtotal += $netchange;
    if($_ <= 4){
        $nOpenTotal += $partsto[1];
        $oOpenTotal += $partslast[1];
    }

    if($netchange > 0){
      $netchange = "+".$netchange;
    }
    print qq~
  <tr>
    <td align="center">
     $partsfrom[0]
    </td>
    <td align="center">
     $partslast[1]
    </td>
    <td align="center">
     $partsto[1]
    </td>
   ~;
      print qq~
    <td align="center">
      $netchange
    </td>
  </tr>
  ~;

}
if($dtotal > 0){
   $dtotal = "+".$dtotal;
}


#Header info
my $openChange = $nOpenTotal - $oOpenTotal;

if($openChange > 0){
   $openChange = "+".$openChange;
}

print qq~
   <tr>
     <td align="center">
      TOTAL OPEN
     </td>
     <td align="center">
      $oOpenTotal
     </td>
     <td align="center">
      $nOpenTotal
     </td>
     <td align="center">
      $openChange
     </td>
   </tr>
   <tr>
     <td align="center">
       TOTAL
     </td>
     <td align="center">
      $ototal
     </td>
     <td align="center">
      $total
     </td>
     <td align="center">
      $dtotal
     </td>
   </tr>
</table>
</center>
</p>
<br />
<br />
<center><b>AppDB Application Status Changes</b></center>
<p><i>*Disclaimer: These lists of changes are automatically  generated by information entered into the AppDB.
These results are subject to the opinions of the users submitting application reviews.
The Wine community does not guarantee that even though an application may be upgraded to 'Gold' or 'Platinum' in this list, that you
will have the same experience and would provide a similar rating.</i></p>
<div align="center">
   <b><u>Updates by App Maintainers</u></b><br /><br />
    <table width="80%" border="1" bordercolor="#222222" cellspacing="0" cellpadding="3">
      <tr>
        <td>
          <b>Application</b>
        </td>
        <td width="140"><b>Old Status/Version</b></td>
        <td width="140"><b>New Status/Version</b></td>
        <td width="20" align="center"><b>Change</b></td>
       </tr>
~;

use DBI;
my $dsn          = "DBI:mysql:appdb;localhost";
#Info from dbsettings.pl
my $dbh          = DBI->connect( $dsn, $db_user_name, $db_pw );
#Reset the total change
my $change          = 0;

#Get, Execute, process, print maintainerQuery
my $query = maintainerQuery();
my $qu = $dbh->prepare($query);
$qu->execute();

my $apps = process($qu);

print_chart($apps);

#Reset change again
$change = 0;

#Run another query
$query = userQuery();
$qu = $dbh->prepare($query);
$qu->execute();

#Print second header
print qq~
  <br />   <b><u> Updates by the Public </u></b> <br /><br />
   <table width="80%" border="1" bordercolor="#222222" cellspacing="0" cellpadding="3">
      <tr>
        <td>
          <b>Application</b>
        </td>
        <td width="140"><b>Old Status/Version</b></td>
        <td width="140"><b>New Status/Version</b></td>
        <td width="20"><b>Change</b></td>
       </tr>

 ~;
$apps = process($qu);

print_chart($apps);

print qq~
</div>
  </section>
~;


sub print_chart{
 my $apps = $_[0];

foreach my $app (sort keys %{$apps} ) {

    my ($maxdate, $oldrating, $newrating, $oldr, $newr);
    my ($oldcolor,$newcolor,$diff,$appname);
    foreach my $tuple ( @{ $apps->{$app} } ) {
        if ( compareDates( $tuple->{"Rdate"}, $maxdate ) ) {
            $maxdate   = $tuple->{"Rdate"};
            $oldrating = $tuple->{"Rrating"} . " (" . $tuple->{"Rwine"} . ")";
            $newrating = $tuple->{"Trating"} . " (" . $tuple->{"Twine"} . ")";
            $oldr      = $tuple->{"Rrating"};
            $newr      = $tuple->{"Trating"};
            $appname = $tuple->{"appName"} . " " . $tuple->{"versionName"};
        }
    }
    if (   !$donealready{$app}
        && $oldr ne $newr
        && $apps->{$app}->[0]->{"Twine"} > $apps->{app}->[0]->{"Rwine"} )
    {
        $donealready{$app} = 1;
        $oldcolor = lc($oldr) . "bg.gif";
        $newcolor = lc($newr) . "bg.gif";
        $oldrating =~ s/\.\)/\)/;
        $newrating =~ s/\.\)/\)/;
        $diff = get_diff( $oldr, $newr );
        if ( length($app) > 50 ) {
            $appname = substr( $app, 0, 50 ) . "...";
        }
        $appname =~ s/\&/\&amp;/g;
        print qq~
           <tr>
             <td>
                <a href="http://appdb.winehq.org/objectManager.php?sClass=version&amp;iId=$apps->{$app}->[0]->{"Tversion"}">$appname</a>
             </td>
             <td background="{\$root}/images/wwn_$oldcolor">
               $oldrating
             </td>
             <td background="{\$root}/images/wwn_$newcolor">
               $newrating
             </td>
             <td align="center">
                $diff
             </td>
           </tr>
    ~;
    }
}
my ($color, $sign);
if ( $change < 0 ) {
    $color = "#990000";
}
else {
    $sign  = "+";
    $color = "#000000";
}
$change = qq~<div style="color: $color;">$sign$change</div>~;

print qq~
           <tr>
             <td colspan="3">
                Total Change
             </td>
             <td align="center">
               $change
             </td>
           </tr>
        </table>
  ~;
}

sub get_diff {
    my ( $old, $new ) = @_;
    $old = numC($old);
    $new = numC($new);
    my $d   = $new - $old;
    $change += $d;
    my $color;
    my $sign;
    if ( $d < 0 ) {
        $color = "#990000";
    }
    else {
        $sign  = "+";
        $color = "#000000";
    }
    return qq~<div style="color: $color;">$sign$d</div>~;
}

sub numC {
    my ($c) = @_;
    if ( $c eq "Garbage" ) {
        return 0;
    }
    elsif ( $c eq "Bronze" ) {
        return 1;
    }
    elsif ( $c eq "Silver" ) {
        return 2;
    }
    elsif ( $c eq "Gold" ) {
        return 3;
    }
    elsif ( $c eq "Platinum" ) {
        return 4;
    }
}

sub compareDates {
    my ( $first, $second ) = @_;
    my @fparts = split( / /, $first );
    my @sparts = split( / /, $second );
    my @fdate  = split( /-/, $fparts[0] );
    my @sdate  = split( /-/, $sparts[0] );
    my @ftime  = split( /-/, $fparts[1] );
    my @stime  = split( /-/, $sparts[1] );

    #start with the date
    #year
    if ( $fdate[0] > $sdate[0] ) {    #fyear > syear
        return 1;
    }
    elsif ( $fdate[0] < $sdate[0] ) {
        return 0;
    }

    #month
    if ( $fdate[1] > $sdate[1] ) {    #fyear > syear
        return 1;
    }
    elsif ( $fdate[1] < $sdate[1] ) {
        return 0;
    }

    #day
    if ( $fdate[2] > $sdate[2] ) {    #fyear > syear
        return 1;
    }
    elsif ( $fdate[2] < $sdate[2] ) {
        return 0;
    }

    #time
    #hour
    if ( $ftime[0] > $stime[0] ) {
        return 1;
    }
    elsif ( $ftime[0] < $stime[0] ) {
        return 0;
    }

    #minute
    if ( $ftime[1] > $stime[1] ) {
        return 1;
    }
    elsif ( $ftime[1] < $ftime[1] ) {
        return 0;
    }

    #second
    if ( $ftime[2] > $stime[2] ) {
        return 1;
    }
    elsif ( $ftime[2] < $ftime[2] ) {
        return 0;
    }
    return 0;    #equal
}

sub process {
    my $qu = $_[0];
    my $apps = {};
    while ( my $row = $qu->fetchrow_hashref ) {
        my $name     = ratingValue($row->{"Trating"}) . $row->{"appName"} . " " . $row->{"versionName"};
        my $arrayref = $apps->{$name};
        if ( !$arrayref ) {
            $arrayref = [];
        }
        push( @$arrayref, $row );
        $apps->{$name} = $arrayref;
    }
    return $apps;
}

sub ratingValue{
  my $rating = shift;
  if ($rating =~ /Platinum/) { return 1; }elsif
  ($rating =~ /Gold/) { return 2; }elsif
  ($rating =~ /Silver/) { return 3; }elsif
  ($rating =~ /Bronze/) { return 4; }else{
  return 5;}

}

sub maintainerQuery {
    return qq~
  SELECT
        R.testedRating as "Rrating",
        T.testedRating as "Trating",
        T.versionId as "Tversion",
        R.versionId as "Rversion",
        T.testedDate as "Tdate",
        R.testedDate as "Rdate",
        R.testingId as "RtId",
        T.testingId as "TtId",
        A.versionName as "versionName",
        R.testedRelease as "Rwine",
        T.testedRelease as "Twine",
        F.appName as "appName"
  FROM
        testResults T,testResults R,appVersion A, appFamily F, appMaintainers M
  WHERE
        T.testedDate > "$fromdate"
        AND T.testedDate < "$todate"
        AND R.versionId = T.versionId
        AND R.testedDate < T.testedDate
        AND A.versionId = T.versionID
        AND F.appId = A.appId
        AND R.state = "accepted"
        AND T.state = "accepted"
        AND M.appID = A.appId
        AND M.userId = T.submitterId
        AND T.testedRelease > R.testedRelease
  ORDER BY
        T.testedDate
~;

}

sub userQuery {
    return qq~
  SELECT
        R.testedRating as "Rrating",
        T.testedRating as "Trating",
        T.versionId as "Tversion",
        R.versionId as "Rversion",
        T.testedDate as "Tdate",
        R.testedDate as "Rdate",
        R.testingId as "RtId",
        T.testingId as "TtId",
        A.versionName as "versionName",
        R.testedRelease as "Rwine",
        T.testedRelease as "Twine",
        F.appName as "appName"
  FROM
        testResults T,testResults R,appVersion A, appFamily F
  WHERE
        T.testedDate > "$fromdate"
        AND T.testedDate < "$todate"
        AND R.versionId = T.versionId
        AND R.testedDate < T.testedDate
        AND A.versionId = T.versionID
        AND F.appId = A.appId
        AND R.state = "accepted"
        AND T.state = "accepted"
        AND T.testedRelease > R.testedRelease
  ORDER BY
        T.testedDate
~;

}
