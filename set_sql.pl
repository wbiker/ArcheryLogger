#!/usr/bin/perl 
#===============================================================================
#
#         FILE: set_sql.pl
#
#        USAGE: ./set_sql.pl  
#
#  DESCRIPTION: 
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 22/09/14 18:31:02
#     REVISION: ---
#===============================================================================
use v5.10;
use strict;
use warnings;
use Data::Printer;
use DBI;
use Storable;

my $db = DBI->connect("dbi:SQLite:dbname=archeryLogger.sqlite", "", "");

my $sth = $db->selectall_arrayref("SELECT * FROM archerysession", { Slice => {} });

my $sessions = [];
foreach my $session (@{$sth}) {
    $session->{pi} = int(($session->{hit_targets} * $session->{score_per_target}) / $session->{levelid});
    printf("sessionid: %s, hit targets: %s, PI: %s\n", $session->{sessionid}, $session->{hit_targets}, $session->{pi});
    push($sessions, $session);
}

my $insert = $db->prepare("UPDATE archerysession set pi = ? WHERE sessionid = ?");
foreach my $s (@$sessions) {
    say "sid: ".$s->{sessionid}." pi: ".$s->{pi};
    $insert->execute($s->{pi}, $s->{sessionid});
}

__END__

