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

use DBI;

my $dh = DBI->connect("dbi:SQLite:dbname=archeryLogger.sqlite", "", "", { RaiseError => 1}) or die $DBI::errstr;

say "Openening DB successfully!";

my $archery_parcour = {};
my $archery_level = {};
my 
