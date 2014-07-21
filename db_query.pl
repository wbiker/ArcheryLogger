#!/usr/bin/perl 
#===============================================================================
#
#         FILE: db_query.pl
#
#        USAGE: ./db_query.pl  
#
#  DESCRIPTION: 
#   Provide commands to insert, update or select data in the sql db
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 21/07/14 17:50:54
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use feature qw(say);
use Time::Piece;
use Data::Printer;

use DBI;
use ArcheryLogger::ArcherySession;
use ArcheryLogger::ArcheryDatabaseWrapper;
#my $dh = DBI->connect("dbi:SQLite:dbname=archeryLogger.sqlite", "", "", { RaiseError => 1}) or die $DBI::errstr;

say "Openening DB successfully!";

my $ses = ArcheryLogger::ArcherySession->new(
    date => time,
    name => "Wolf",
    parcour => 20,
    level => "Rot",
    targets => [
        { 1 => 20 },
        { 2 => 18 },
        { 4 => 16 },
    ],
    max_score => 300,
    score_per_target => 13.2,
    );


my $db = ArcheryLogger::ArcheryDatabaseWrapper->new(user => "", password => "", dbname => "archeryLogger.sqlite");

p $db;
