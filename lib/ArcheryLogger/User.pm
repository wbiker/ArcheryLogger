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
	my @recurve = ();
	my @compound = ();
    for my $session (@{$sessions}) {
		if(2 == $session->{bow_id}) {
			@recurve = ([],[]) unless @recurve;
			push($recurve[0], $session->{date});
			push($recurve[1], $session->{score_per_hit_targets});
		}
		if(3 == $session->{bow_id}) {
			@compound = ([],[]) unless @compound;
			push($compound[0], $session->{date});
			push($compound[1], $session->{score_per_hit_targets});
		}
		if(1 == $session->{bow_id}) {
			push($data[0], $session->{date});
			push($data[1], $session->{score_per_hit_targets});
		}
    }

    my $g = GD::Graph::lines->new();
    $g->set(zero_axis => 1, values_vertical => 1, x_number_format => \&turn_label);
	if(@data) {
		my $gd = $g->plot(\@data) or print $g->error;
    
		my $image_base64_enc = encode_base64($gd->png);
		$self->stash(image_other => $image_base64_enc);
	}
    $g = GD::Graph::lines->new();
    $g->set(zero_axis => 1, values_vertical => 1, x_number_format => \&turn_label);
	if(@recurve) {
		my $gd = $g->plot(\@recurve) or print $g->error;
    
		my $image_base64_enc = encode_base64($gd->png);
		$self->stash(image_recurve => $image_base64_enc);
	}
    $g = GD::Graph::lines->new();
    $g->set(zero_axis => 1, values_vertical => 1, x_number_format => \&turn_label);
	if(@compound) {
		my $gd = $g->plot(\@compound) or print $g->error;
    
		my $image_base64_enc = encode_base64($gd->png);
		$self->stash(image_compound => $image_base64_enc);
	}
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
