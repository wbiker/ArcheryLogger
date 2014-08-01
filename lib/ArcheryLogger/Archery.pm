package ArcheryLogger::Archery;
use Mojo::Base 'Mojolicious::Controller';
use Data::Printer;

sub login {
    my $self = shift;
}

sub logout {
    my $self = shift;

    $self->app->logout;
    delete $self->session->{authenticated};

    $self->redirect_to('/');
}

sub login_check {
    my $self = shift;

    my $user_name = $self->req->param('username');
    my $user_password = $self->req->param('userpassword');

    say "user: ", $user_name;
    say "pw: ", $user_password;

    if ($self->app->authenticate($user_name, $user_password)) {
        say "authenticated";
        $self->session(authenticated => 1);
        p $self;
    } else {
        say "not authenticated";
    }

    $self->redirect_to('/');
}

1;
