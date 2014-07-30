package ArcheryLogger;
use Mojo::Base 'Mojolicious';
use Mojolicious::Plugin::Database;
use Data::Printer;

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

  #push(@{$self->static->paths}, $ENV{PWD}."/root");
  #p $self->static;

  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->get('/')->to('Session#list_sessions');
  $r->get('/new_session')->to('Session#new_session');
  $r->get('/delete_session/:sessionid')->to('Session#delete_session');
  $r->post('/new_session')->to('Session#new_session');
}

1;
