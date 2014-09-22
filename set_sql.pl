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
__END__
my $db = DBI->connect("dbi:SQLite:dbname=archeryLogger.sqlite", "", "");

my $sessions = retrieve 'sessions';
my $insert = $db->prepare("UPDATE archerysession set pi = ? WHERE sessionid = ?");
foreach my $s (@$sessions) {
    say "sid: ".$s->{sessionid}." pi: ".$s->{pi};
    $insert->execute($s->{pi}, $s->{sessionid});
}
__END__
my $sth = $db->selectall_arrayref("SELECT * FROM archerysession WHERE pi = '-1'", { Slice => {} });

my $sessions = [];
foreach my $session (@{$sth}) {
    $session->{pi} = int(($session->{hit_targets} * 3) / $session->{levelid});
    printf("sessionid: %s, hit targets: %s, PI: %s\n", $session->{sessionid}, $session->{hit_targets}, $session->{pi});
    push($sessions, $session);
}

__END__

