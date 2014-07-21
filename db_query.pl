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
use Getopt::Long;

use ArcheryLogger::ArcherySession;
use ArcheryLogger::ArcheryDatabaseWrapper;

# command parameter


my $db = ArcheryLogger::ArcheryDatabaseWrapper->new(dbname => "archeryLogger.sqlite");


