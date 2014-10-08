package ArcheryLogger;
use utf8;
use Mojo::Base 'Mojolicious';
use Mojolicious::Plugin::Database;
use Mojolicious::Plugin::Authentication;
use Data::Printer;
use HTML::Entities;
use Time::Piece; 

# This method will run once at server start
sub startup {
  my $self = shift;

  # Documentation browser under "/perldoc"
  $self->plugin('PODRenderer');
    $self->plugin('database', {
        dsn => 'dbi:SQLite:dbname=archeryLogger.sqlite',
        username => '',
        password => '',
        options => { 'foreign_keys' => 1 },
        helper => 'db',
    });

    $self->plugin('authentication', {
        autoload_user => 1,
        load_user => sub {
            my $self = shift;
            my $uid = shift;

            #my @user_row = $self->db->selectrow_array('SELECT * FROM archerycredentials WHERE userid = ?', [$uid]);

            return "wolf";
        },
        validate_user => sub {
            my $self = shift;
            my $uid = shift // '';
            my $pw = shift // '';
            my $extra = shift // {};
            use Authen::Simple::DBI;

            my $authDB = Authen::Simple::DBI->new(
                dsn => 'dbi:SQLite:dbname=archeryLogger.sqlite',
                username => '',
                password => '',
                statement => 'SELECT userpw FROM archerycredentials WHERE userid = ?',
                );

            return $uid if ($authDB->authenticate($uid, $pw));

            return undef;
        },
    });
  #push(@{$self->static->paths}, $ENV{PWD}."/root");
  #p $self->static;

  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->get('/login')->to('Archery#login');
  $r->get('/logout')->to('Archery#logout');
  $r->get('/')->to('Session#list_sessions');
  $r->get('/list_sessions')->to('Session#list_sessions');
  $r->get('/session/:epoch')->to('Session#show_sessions');
  $r->get('/new_session')->to('Session#new_session');
  $r->get('/delete_session/:sessionid')->to('Session#delete_session');
  $r->get('/users/:user_id')->to('User#list_user');
  $r->post('/new_session')->to('Session#new_session');
  $r->post('/login')->to('Archery#login_check');
  $r->post('/picture/store')->to('Picture#store_picture');

}

sub remove_session {
    my $self = shift;
    my $id = shift;

    my $db = $self->db;
    $db->do("DELETE FROM archerysession WHERE sessionid = ?", undef, $id) or say $db->errstr;
    $db->do("DELETE FROM archeryshot WHERE sessionid = ?", undef, $id) or say $db->errstr;
}

sub get_targets {
    my $self = shift;
    my $params = shift;
    my $parcour = shift // 28;
    my $db = $self->db;

    my $scorevalue = $self->get_scores_by_value();
    my $targets = {};
    # go through the targets
    for (my $i=1; $i<=$parcour; $i++) {
        if(exists $params->{$i}) {
            # store the score id in the hash with the target id as key.
            $targets->{$i} = $params->{$i};
        }
        else {
            $targets->{$i} = $scorevalue->{0};
        }
    }

    return $targets;
}

sub store_new_session {
    my $self = shift;
    my $session = shift;

    my $db = $self->db;
    my $insert_sth = $db->prepare("INSERT INTO archerysession(parcourid, nameid, levelid, date_epoch, max_score, score_per_target, missed_targets, hit_targets, score_per_hit_targets, note, pi) VALUES(?,?,?,?,?,?,?,?,?,?,?)");

	# bug warning:
	# $session->{level} is the levelid. At the moment it works because 
	# Red is 1, blue is 2 and green is 3.
	# Should that change in the future the pi feature will be broken.
	my $pi = int(($session->{hit_targets} * $session->{score_per_target}) / $session->{level});
    my $rc = $insert_sth->execute($session->{parcour}, $session->{name}, $session->{level}, $session->{date}, $session->{total_score}, $session->{score_per_target}, $session->{missed_targets}, $session->{hit_targets}, $session->{score_per_hit_targets}, $session->{note}, $pi);
    
    my $session_id = $db->last_insert_id(undef, undef, 'archerysession', undef);
    if($session_id) {
        # all went fine insert targets
        my $targets = $session->{targets};

        my $insert_sth = $db->prepare("INSERT INTO archeryshot(sessionid, targetid, scoreid) VALUES(?, ?, ?)");
        foreach my $target (keys %{$targets}) {
            $insert_sth->execute($session_id, $target, $targets->{$target});
        }
    }

    #my $meta_session_sth = $db->prepare("INSERT INTO archerymetasession(dateepoch) VALUES(?)");
    # store targets:
    # first need last_insert_id
}

sub get_all_sessions {
    my $self = shift;
	my $filter_name = shift // "all";
    my $filter_parcour = shift // 'all';
    my $db = $self->db;

    my $names = $self->get_names_by_id();
    my $parcours = $self->get_parcours_by_id();
    my $levels = $self->get_levels_by_id();

    my $sessions = [];
    my $sth = $db->prepare("SELECT * FROM archerysession");
    $sth->execute;
    while(my $session = $sth->fetchrow_hashref) {
        my $date = $session->{date_epoch};
        $date = Time::Piece->new($date)->dmy('.');
        my $name = $names->{$session->{nameid}};
        my $parcour = $parcours->{$session->{parcourid}};
        my $level = $levels->{$session->{levelid}};

		my $note = $session->{note};
        my $parcour_id = $session->{parcourid};
		if($filter_name eq "all" || $filter_name eq $session->{nameid}) {
            if($filter_parcour eq 'all' || $filter_parcour eq $parcour_id) {
            	push($sessions, {
        	        date => $date,
                    date_epoch => $session->{date_epoch},
	                name => $name,
                    name_id => $session->{nameid},
                	parcour => $parcour,
            	    max_score => $session->{max_score},
        	        score_per_target => $session->{score_per_target},
        	        score_per_hit_targets => $session->{score_per_hit_targets},
	                id => $session->{sessionid},
                    level => $level,
                    missed_targets => $session->{missed_targets},
    				hit_targets => $session->{hit_targets},
				    note => $note,
                    pi => $session->{pi},
        	    });
            }
		}
    }

    return $sessions;
}

sub get_all_sessions_by_epoch {
    my $self = shift;
    my $epoch = shift;

    my $names = $self->get_names_by_id();
    my $parcours = $self->get_parcours_by_id();
    my $levels = $self->get_levels_by_id();

    my $sth = $self->db->prepare("SELECT * FROM archerysession WHERE date_epoch = ?");
    
    my $sessions = [];
    $sth->execute($epoch);
    while(my $session = $sth->fetchrow_hashref) {
        my $date = $session->{date_epoch};
        $date = Time::Piece->new($date)->dmy('.');
        my $name = $names->{$session->{nameid}};
        my $parcour = $parcours->{$session->{parcourid}};
        my $level = $levels->{$session->{levelid}};

		my $note = $session->{note};
        my $parcour_id = $session->{parcourid};
            	push($sessions, {
        	        date => $date,
                    date_epoch => $session->{date_epoch},
	                name => $name,
                    name_id => $session->{nameid},
                	parcour => $parcour,
            	    max_score => $session->{max_score},
        	        score_per_target => $session->{score_per_target},
        	        score_per_hit_targets => $session->{score_per_hit_targets},
	                id => $session->{sessionid},
                    level => $level,
                    missed_targets => $session->{missed_targets},
    				hit_targets => $session->{hit_targets},
				    note => $note,
                    pi => $session->{pi},
        	    });
    }
    return $sessions;
}

sub get_names_by_id {
    my $self = shift;
    my $db = $self->db;

    my $names = {};
    my $name_ref = $db->selectall_hashref('SELECT * FROM archeryname', 'nameid');

    foreach my $name_id (keys %{$name_ref}) {
        $names->{$name_id} = $name_ref->{$name_id}->{name_value};
    }

    return $names;
}

sub get_parcours_by_id {
    my $self = shift;
    my $db = $self->db;

    my $parcours = {};
    my $parcour_ref = $db->selectall_hashref('SELECT * FROM archeryparcour', 'parcourid');

    foreach my $parcour_id (keys %{$parcour_ref}) {
        $parcours->{$parcour_id} = $parcour_ref->{$parcour_id}->{parcour_value};
    }

    return $parcours;
}

sub get_scores_by_id {
    my $self = shift;
    my $db = $self->db;

    my $scores = {};
    my $score_ref = $db->selectall_hashref('SELECT * FROM archeryscore', 'scoreid');

    foreach my $score_id (keys %{$score_ref}) {
        $scores->{$score_id} = $score_ref->{$score_id}->{score_value};
    }

    return $scores;
}

sub get_scores_by_value {
    my $self = shift;
    my $db = $self->db;

    my $scores = {};
    my $score_ref = $db->selectall_hashref('SELECT * FROM archeryscore', 'score_value');

    foreach my $score_value (keys %{$score_ref}) {
        $scores->{$score_value} = $score_ref->{$score_value}->{scoreid};
    }

    return $scores;
}

sub get_levels_by_id  {
    my $self = shift;
    my $db = $self->db;

    my $levels = {};
    my $level_ref = $db->selectall_hashref('SELECT * FROM archerylevel', 'levelid');

    foreach my $level_id (keys %{$level_ref}) {
        $levels->{$level_id} = $level_ref->{$level_id}->{level_name};
    }

    return $levels;
}

sub get_targets_by_id  {
    my $self = shift;
    my $db = $self->db;

    my $targets = {};
    my $targets_ref = $db->selectall_hashref('SELECT * FROM archerytarget', 'targetid');

    foreach my $target_id (keys %{$targets_ref}) {
        $targets->{$target_id} = $targets_ref->{$target_id}->{target_name};
    }

    return $targets;
}

sub insert_picture {
    my $self = shift;
    my $file = shift;
    my $epoch = shift;
    my $width = shift;
    my $height = shift;

    my $pic_sth = $self->db->prepare("INSERT INTO archerypicture(picture, dateepoch, picturewidth, pictureheight) VALUES(?,?,?,?)");
    $pic_sth->execute($file, $epoch, $width, $height);
}

sub get_all_pictures_by_epoch {
    my $self = shift;
    my $epoch = shift;

    my $pics_array = $self->db->selectall_arrayref("SELECT picture, picturewidth, pictureheight FROM archerypicture WHERE dateepoch = '$epoch'", { Slice => {}});
    
    my $pictures = [];
    foreach my $pic (@{$pics_array}) {
        my $width = $pic->{picturewidth};
        my $height = $pic->{pictureheight};
        $width = int($width / 3);
        $height = int($height / 3);
        push($pictures, { picture =>  $pic->{picture}, width => $width, height => $height});
    }

    return $pictures;
}

1;
