package ArcheryLogger::Session;
use Mojo::Base 'Mojolicious::Controller';
use Data::Printer;
use Time::Piece;
use utf8;

sub list_sessions {
    my $self = shift;

	my $name_filter = $self->req->param('selected_name') // 'all';
    my $parcour_filter = $self->req->param('selected_parcour') // 'all';

	my $sessions = $self->app->get_all_sessions($name_filter, $parcour_filter);

	my $names = $self->app->get_names_by_id();
	# sort names by name for the filter popup
	my @names = sort { $names->{$a} cmp $names->{$b} } (keys %{$names});

	my @names_sorted;
	foreach my $id (@names) {
		push(@names_sorted, { id => $id, name => $names->{$id} });
	}

    my $parcours = $self->app->get_parcours_by_id();
    my @pars = sort { $parcours->{$a} cmp $parcours->{$b} } (keys %{$parcours});

    my $parcours_sorted = [];
    foreach my $parcour_id (@pars) {
        push($parcours_sorted, {id => $parcour_id, name => $parcours->{$parcour_id}});
    }

    $self->render(template => 'session/list_sessions', sessions => $sessions, authorized => $self->app->is_user_authenticated, selected_name => $name_filter, names => \@names_sorted, parcour_names => $parcours_sorted, selected_parcour => $parcour_filter);
}

sub show_sessions {
    my $self = shift;
    my $epoch = $self->param('epoch');

    my $sessions = $self->app->get_all_sessions_by_epoch($epoch);

    my $pictures = $self->app->get_all_pictures($epoch);
    $self->stash(pictures => $pictures); 
    $self->stash(epoch => $epoch);
    my $auth = $self->app->is_user_authenticated;
    $self->app->log->debug("Auth: ".$auth);
    $self->render(template => 'session/show_sessions', sessions => $sessions, authorized => $auth);
}

# This action will render a template
sub new_session {
  my $self = shift;

  if($self->req->method eq "POST") {

    my $p = $self->req->params;
    my $params = { @{$p} };
    my $session = {};
    $session->{name} = delete $params->{name};
    $session->{parcour} = delete $params->{parcour};
    $session->{date} = delete $params->{date};
    $session->{level} = delete $params->{level};
	$session->{note} = delete $params->{note};
	$session->{bow} = delete $params->{bow};

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
	my $nameid = $self->app->get_names_by_id();
	my $bowid = $self->app->get_bows_by_id();

    $self->render(targetid => $targetid, scorevalue => $scorevalue, parcourid => $parcourid, nameid => $nameid, bowid => $bowid);
  }
}

sub get_targets {
	my $self = shift;
	my $parcourid = $self->param('parcourid') // 3;

	my $targets = $self->app->get_target_array($parcourid);

	$self->render(json => $targets);
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
