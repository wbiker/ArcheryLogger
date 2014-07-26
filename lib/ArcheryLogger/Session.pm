package ArcheryLogger::Session;
use Mojo::Base 'Mojolicious::Controller';
use Data::Printer;

sub list_sessions {
    my $self = shift;

    $self->render;
}

# This action will render a template
sub new_session {
  my $self = shift;

  if($self->req->method eq "POST") {
      $self->render(msg => "Post message");

    my $p = $self->req->params->params;
    my $params = { @{$p} };
    my $session = {};
    $session->{name} = delete $params->{name};
    $session->{parcour} = delete $params->{parcour};
    $session->{date} = delete $params->{date};
    $session->{level} = delete $params->{level};

    my $targets = get_targets($params, $session->{parcour});
    p $targets;

    my $total_sum;
    foreach my $key (keys %{$targets}) {
        $total_sum += $targets->{$key};
    }
    my $score_per_target = $total_sum / int($session->{parcour});

    $session->{score_per_target} = sprintf("%.2f", $score_per_target);
    $session->{total_score} = $total_sum;
    $session->{targets} = $targets;
    $self->render(session => $session);
  }
  else {
    # Render template "example/welcome.html.ep" with message
     $self->render(msg => "Please fill out");
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

1;
