package ArcheryLogger::Session;
use Mojo::Base 'Mojolicious::Controller';
use Data::Printer;
use Time::Piece;

sub list_sessions {
    my $self = shift;

    my $sessions = $self->app->get_all_sessions();

    $self->render(template => 'session/list_sessions', sessions => $sessions);
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
    my $score_per_target = $total_sum / $parcourid->{$session->{parcour}};

    $session->{score_per_target} = sprintf("%.2f", $score_per_target);
    $session->{total_score} = $total_sum;
    $session->{targets} = $targets;

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

sub delete_session {
    my $self = shift;

    my $params = $self->req->params->to_hash;
    
    my $sessionid = $self->stash('sessionid');
    if($sessionid) {
        # remove session with id wihtin params
        $self->app->remove_session($sessionid);
    }
    $self->redirect_to('/');
}

1;
