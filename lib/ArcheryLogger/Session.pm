package ArcheryLogger::Session;
use Mojo::Base 'Mojolicious::Controller';
use Data::Printer;
use Time::Piece;

sub list_sessions {
    my $self = shift;

    my $db = $self->db;

    my $namesth = $db->prepare("SELECT * FROM archeryname");
    $namesth->execute;
    my $names = {};
    while(my $row = $namesth->fetchrow_hashref) {
        $names->{$row->{nameid}} = $row->{name_value};
    }

    my $parcoursth = $db->prepare("SELECT * FROM archeryparcour");
    $parcoursth->execute;
    my $parcours = {};
    while(my $row = $parcoursth->fetchrow_hashref) {
        $parcours->{$row->{parcourid}} = $row->{parcour_value};
    }

    my $sessions = [];
    my $sth = $db->prepare("SELECT * FROM archerysession");
    $sth->execute;
    while(my $session = $sth->fetchrow_hashref) {
        p $session;
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
    my $parcoursth = $self->db->prepare("SELECT * FROM archeryparcour");
    $parcoursth->execute;

    my $parcourid = $parcoursth->fetchall_hashref('parcourid');

    my $targets = get_targets($params, $parcourid->{$session->{parcour}}->{parcour_value});

    my $scoresth = $self->db->prepare("SELECT * FROM archeryscore");
    $scoresth->execute;
    my $scoreids = $scoresth->fetchall_hashref('scoreid');
    
    my $total_sum;
    foreach my $key (keys %{$targets}) {
        $total_sum += $scoreids->{$targets->{$key}}->{score_value};
    }
    my $score_per_target = $total_sum / $parcourid->{$session->{parcour}}->{parcour_value};

    $session->{score_per_target} = sprintf("%.2f", $score_per_target);
    $session->{total_score} = $total_sum;
    $session->{targets} = $targets;

    store_new_session($self->db, $session);
    $self->render(session => $session);
  }
  else {
    # Render template "example/welcome.html.ep" with message
    my $db = $self->db;
    my $st = $db->prepare("SELECT * FROM archeryscore");
    $st->execute;
    my $scoreid = $st->fetchall_hashref('score_value');

    my $targets_sth = $db->prepare("SELECT * FROM archerytarget");
    $targets_sth->execute;
    my $targetid = $targets_sth->fetchall_hashref('targetid');

    my $parcoursth = $db->prepare("SELECT * FROM archeryparcour");
    $parcoursth->execute;
    my $parcourid = $parcoursth->fetchall_hashref('parcour_value');
     $self->render(scoreid => $scoreid, targetid => $targetid, parcourid => $parcourid);
  }
}

sub get_targets {
    my $params = shift;
    my $parcour = shift // 28;

    my $targets = {};
    # go through the targets
    for (my $i=1; $i<=$parcour; $i++) {
        if(exists $params->{$i}) {
            $targets->{$i} = $params->{$i};
        }
        else {
            $targets->{$i} = 0;
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

1;
