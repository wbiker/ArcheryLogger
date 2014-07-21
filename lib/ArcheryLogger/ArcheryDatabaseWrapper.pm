#
#===============================================================================
#
#         FILE: ArcheryDatabaseWrapper.pm
#
#  DESCRIPTION: Wraps the sqlite database as class 
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 21/07/14 19:32:40
#     REVISION: ---
#===============================================================================

package ArcheryLogger::ArcheryDatabaseWrapper;

use Moo;
use strict;
use warnings;
use Data::Printer;

use DBI;

has dbh => (is => 'rw');
has names => (is => 'rw');
has scores => (is => 'rw');
has levels => (is => 'rw');
has parcours => (is => 'rw');

sub BUILDARGS {
    my ($class, @args) = @_;

    p $class;

    my $args = {@args};

    my $dbname = $args->{dbname} // '../../archeryLogger.sqlite';

    my $dbh = DBI->connect("dbi:SQLite:dbname=$dbname", "", "") or die $DBI::errstr;

    $args->{dbh} = $dbh;

    # fetch names
    my $names = {};

    my $st = $dbh->prepare("SELECT nameid, name_value FROM archeryname");
    $st->execute;
    $args->{names} = $st->fetchall_hashref('nameid');

    $st = $dbh->prepare("SELECT scoreid, score_value FROM archeryscore");
    $st->execute;
    $args->{scores} = $st->fetchall_hashref('scoreid');

    $st = $dbh->prepare("SELECT parcourid, parcour_value FROM archeryparcour");
    $st->execute;
    $args->{parcours} = $st->fetchall_hashref('parcourid');

    $st = $dbh->prepare("SELECT levelid, level_name FROM archerylevel");
    $st->execute;
    $args->{levels} = $st->fetchall_hashref('levelid');

    return $args;
};

sub get_all_sessions {
    
}

1;
