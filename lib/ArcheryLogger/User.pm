package ArcheryLogger::User
use Mojo::Base 'Mojolicious::Controller';
use Data::Printer;
use Time::Piece;
use utf8;

sub list_users {
    my $self = shift;
    

}

sub list_user {
    my $self = shift;

    my $user_id = $self->param('user_id');
}

1;
