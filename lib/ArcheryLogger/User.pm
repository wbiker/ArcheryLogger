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
	$self->stash(user_id => $user_id);
}

sub get_statistic {
	my $self = shift;

    my $user_id = $self->param('user_id');

    my $sessions = $self->app->get_all_sessions($user_id, "all");

    $self->stash(sessions => $sessions);

    # create image
    # first gather values
    my @data = ();
	my @recurve = ();
	my @compound = ();
    for my $session (@{$sessions}) {
		if(2 == $session->{bow_id}) {
			push(@recurve, [$session->{date}, $session->{score_per_hit_targets}]);
		}
		if(3 == $session->{bow_id}) {
			push(@compound, [$session->{date}, $session->{score_per_hit_targets}]);
		}
		if(1 == $session->{bow_id}) {
			push(@data, [$session->{date}, $session->{score_per_hit_targets}]);
		}
    }

	my $data_to_send = {};

	if(@data) {
		push(@{$data_to_send->{data}}, @data);
	}
	
	if(@compound) {
		push(@{$data_to_send->{compound}}, @compound);
	}

	if(@recurve) {
		push(@{$data_to_send->{recurve}}, @recurve);
	}

	$self->render(json => $data_to_send);
}

sub turn_label {
    my $label = shift;

    my @characters = split('', $label);
    my $ret = "";
    for my $chat (@characters) {
        $ret .= "$chat\n";
    }
    print $ret;
    return $ret;
}

1;
