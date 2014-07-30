package ArcheryLogger::Session;
use Mojo::Base 'Mojolicious::Controller';
use Data::Printer;
use Time::Piece;

sub list_sessions {
    my $self = shift;

    my $db = $self->db;

    my $sessions = get_all_sessions($db);

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

    my $parcourid = get_parcours_by_id($self->db);
    my $scoreids = get_scores_by_id($self->db);
    my $targets = get_targets($params, $parcourid->{$session->{parcour}}, $self->db);
    
    my $total_sum = 0;
    foreach my $key (keys %{$targets}) {
        my $sum = $scoreids->{$targets->{$key}};
        $total_sum += $sum;
    }
    my $score_per_target = $total_sum / $parcourid->{$session->{parcour}};

    $session->{score_per_target} = sprintf("%.2f", $score_per_target);
    $session->{total_score} = $total_sum;
    $session->{targets} = $targets;

    store_new_session($self->db, $session);
    $self->redirect_to('/');
  }
  else {
    my $scorevalue = get_scores_by_value($self->db); # in the template the score IDs are got by the values. These are used as Value for the target checkboxes
    my $targetid = get_targets_by_id($self->db);
    my $parcourid = get_targets_by_id($self->db);
    $self->render(targetid => $targetid, scorevalue => $scorevalue, parcourid => $parcourid);
  }
}

sub delete_session {
    my $self = shift;

    my $params = $self->req->params->to_hash;
    
    my $sessionid = $self->stash('sessionid');
    if($sessionid) {
        # remove session with id wihtin params
        remove_session($self->db, $sessionid);
    }
    $self->redirect_to('/');
}

sub remove_session {
    my $db = shift;
    my $id = shift;

    $db->do("DELETE FROM archerysession WHERE sessionid = ?", undef, $id) or say $db->errstr;
    $db->do("DELETE FROM archeryshot WHERE sessionid = ?", undef, $id) or say $db->errstr;
}

sub get_targets {
    my $params = shift;
    my $parcour = shift // 28;
    my $db = shift;

    my $scorevalue = get_scores_by_value($db);
    my $targets = {};
    # go through the targets
    for (my $i=1; $i<=$parcour; $i++) {
        if(exists $params->{$i}) {
            $targets->{$i} = $params->{$i};
        }
        else {
            $targets->{$i} = $scorevalue->{0};
        }
    }

    return $targets;
}

sub store_new_session {
    my $db = shift;
    my $session = shift;

    my $insert_sth = $db->prepare("INSERT INTO archerysession(parcourid, nameid, levelid, date_epoch, max_score, score_per_target) VALUES(?,?,?,?,?,?)");

    my $rc = $insert_sth->execute($session->{parcour}, $session->{name}, $session->{level}, $session->{date}, $session->{total_score}, $session->{score_per_target});
    
    my $session_id = $db->last_insert_id(undef, undef, 'archerysession', undef);
    if($session_id) {
        # all went fine insert targets
        my $targets = $session->{targets};

        my $insert_sth = $db->prepare("INSERT INTO archeryshot(sessionid, targetid, scoreid) VALUES(?, ?, ?)");
        foreach my $target (keys %{$targets}) {
            $insert_sth->execute($session_id, $target, $targets->{$target});
        }
    }

    # store targets:
    # first need last_insert_id
}

sub get_all_sessions {
    my $db = shift;

    my $names = get_names_by_id($db);
    my $parcours = get_parcours_by_id($db);

    my $sessions = [];
    my $sth = $db->prepare("SELECT * FROM archerysession");
    $sth->execute;
    while(my $session = $sth->fetchrow_hashref) {
        my $date = $session->{date_epoch};
        $date = Time::Piece->new($date)->dmy('.');
        my $name = $names->{$session->{nameid}};
        my $parcour = $parcours->{$session->{parcourid}};
        push($sessions, {
            date => $date,
            name => $name,
            parcour => $parcour,
            max_score => $session->{max_score},
            score_per_target => $session->{score_per_target},
            id => $session->{sessionid},
        });
    }

    return $sessions;
}

sub get_names_by_id {
    my $db = shift;

    my $names = {};
    my $name_ref = $db->selectall_hashref('SELECT * FROM archeryname', 'nameid');

    foreach my $name_id (keys %{$name_ref}) {
        $names->{$name_id} = $name_ref->{$name_id}->{name_value};
    }

    return $names;
}

sub get_parcours_by_id {
    my $db = shift;

    my $parcours = {};
    my $parcour_ref = $db->selectall_hashref('SELECT * FROM archeryparcour', 'parcourid');

    foreach my $parcour_id (keys %{$parcour_ref}) {
        $parcours->{$parcour_id} = $parcour_ref->{$parcour_id}->{parcour_value};
    }

    return $parcours;
}

sub get_scores_by_id {
    my $db = shift;

    my $scores = {};
    my $score_ref = $db->selectall_hashref('SELECT * FROM archeryscore', 'scoreid');

    foreach my $score_id (keys %{$score_ref}) {
        $scores->{$score_id} = $score_ref->{$score_id}->{score_value};
    }

    return $scores;
}

sub get_scores_by_value {
    my $db = shift;

    my $scores = {};
    my $score_ref = $db->selectall_hashref('SELECT * FROM archeryscore', 'score_value');

    foreach my $score_value (keys %{$score_ref}) {
        $scores->{$score_value} = $score_ref->{$score_value}->{scoreid};
    }

    return $scores;
}

sub get_levels_by_id  {
    my $db = shift;

    my $levels = {};
    my $level_ref = $db->selectall_hashref('SELECT * FROM archerylevel', 'levelid');

    foreach my $level_id (keys %{$level_ref}) {
        $levels->{$level_id} = $level_ref->{$level_id}->{level_name};
    }

    return $levels;
}

sub get_targets_by_id  {
    my $db = shift;

    my $targets = {};
    my $targets_ref = $db->selectall_hashref('SELECT * FROM archerytarget', 'targetid');

    foreach my $target_id (keys %{$targets_ref}) {
        $targets->{$target_id} = $targets_ref->{$target_id}->{target_name};
    }

    return $targets;
}

1;
