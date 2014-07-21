package ArcheryLogger::ArcherySession;

use Moo;
use Time::Piece;

has date => (is => 'ro');
has name => (is => 'ro');
has level => (is => 'ro');
has parcour => (is => 'ro');
has max_score => (is => 'ro');
has score_per_target => (is => 'ro');
has targets => (is => 'ro');

1;
