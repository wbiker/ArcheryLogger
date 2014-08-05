package ArcheryLogger::Session;
use Mojo::Base 'Mojolicious::Controller';
use Data::Printer;
use Time::Piece;

sub list_sessions {
    my $self = shift;

	my $name_filter = $self->req->param('selected_name') // 'all';
	my $sessions = $self->app->get_all_sessions($name_filter);
	my $names = $self->app->get_names_by_id();
	# sort names by name for the filter popup
	my @names = sort { $names->{$a} cmp $names->{$b} } (keys %{$names});

	my @names_sorted;
	foreach my $id (@names) {
		push(@names_sorted, { id => $id, name => $names->{$id} });
	}

    $self->render(template => 'session/list_sessions', sessions => $sessions, authorized => $self->app->is_user_authenticated, selected_name => $name_filter, names => \@names_sorted);
}

# This action will render a template
sub new_session {
  my $self = shift;

  if($self->req->method eq "POST") {

    my $p = $self->req->params->params;
    my $params = { @{$p} };
    my $session = {};
    $session->{name} = delete $params->{name};
    $session->{parcour} = delete $params->{parcour};
    $session->{date} = delete $params->{date};
    $session->{level} = delete $params->{level};
	$session->{note} = delete $params->{note};

    my $time = Time::Piece->strptime($session->{date}, "%d.%m.%Y");
    $session->{date} = $time->epoch;

    my $parcourid = $self->app->get_parcours_by_id();
    my $scoreids = $self->app->get_scores_by_id();
    my $targets = $self->app->get_targets($params, $parcourid->{$session->{parcour}}, $self->db);
    
    my $total_sum = 0;
    foreach my $key (keys %{$targets}) {
        my $sum = $scoreids->{$targets->{$key}};
        $total_sum += $sum;
    }
    my ($missed_targets, $hit_targets) = $self->_get_missed_targets($targets);
    my $score_per_target = $total_sum / $parcourid->{$session->{parcour}};
	my $score_per_hit_targets = $total_sum / $hit_targets;

    $session->{score_per_target} = sprintf("%.2f", $score_per_target);
    $session->{score_per_hit_targets} = sprintf("%.2f", $score_per_hit_targets);
    $session->{total_score} = $total_sum;
    $session->{targets} = $targets;
    $session->{missed_targets} = $missed_targets;
    $session->{hit_targets} = $hit_targets;

    $self->app->store_new_session($session);
    $self->redirect_to('/');
  }
  else {
    my $scorevalue = $self->app->get_scores_by_value(); # in the template the score IDs are got by the values. These are used as Value for the target checkboxes
    my $targetid = $self->app->get_targets_by_id();
    my $parcourid = $self->app->get_targets_by_id();
    $self->render(targetid => $targetid, scorevalue => $scorevalue, parcourid => $parcourid);
  }
}

sub _get_missed_targets {
    my $self = shift;
    my $targets = shift;

    my $score_names = $self->app->get_scores_by_value();
    my $null_score_id = $score_names->{0};
    my $missed_targets = 0;
	my $hit_targets = 0;
    foreach my $target (keys %{$targets}) {
        if($targets->{$target} == $null_score_id) {
			$missed_targets++;
		} else {
			$hit_targets++;
		}
    }

    return ($missed_targets, $hit_targets);
}

sub delete_session {
    my $self = shift;

    if($self->session('authenticated')) {
        my $params = $self->req->params->to_hash;
    
        my $sessionid = $self->stash('sessionid');
        if($sessionid) {
            # remove session with id wihtin params
            $self->app->remove_session($sessionid);
        }
    }

    $self->redirect_to('/');
}

1;
