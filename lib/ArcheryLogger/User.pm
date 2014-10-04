package ArcheryLogger::User;
use Mojo::Base 'Mojolicious::Controller';
use Data::Printer;
use MIME::Base64;
use Time::Piece;
use GD::Graph::lines;
use utf8;

sub list_users {
    my $self = shift;
    

}

sub list_user {
    my $self = shift;

    my $user_id = $self->param('user_id');

    my $sessions = $self->app->get_all_sessions($user_id, "all");

    $self->stash(sessions => $sessions);

    # create image
    # first gather values
    my @data = ( [], [] );
    my $counter = 0;
    for my $session (@{$sessions}) {
        push($data[0], $session->{date});
        push($data[1], $session->{score_per_hit_targets});
    }

    my $g = GD::Graph::lines->new();
    $g->set(zero_axis => 1, values_vertical => 1);
    my $gd = $g->plot(\@data) or print $g->error;
    
    my $image_base64_enc = encode_base64($gd->png);
    $self->stash(image => $image_base64_enc);
}

1;
