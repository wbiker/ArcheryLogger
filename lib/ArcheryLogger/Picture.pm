package ArcheryLogger::Picture;
use Mojo::Base 'Mojolicious::Controller';
use Data::Printer;
use Time::Piece;
use MIME::Base64 qw(encode_base64);
use GD;
use GD::Image;
use utf8;

sub store_picture {
    my $self = shift;
    my $file = $self->param('file');
    my $epoch = $self->param('epoch');

    my $sourceImg = GD::Image->new($file->slurp);
    my $source_width = $sourceImg->width;
    my $source_height = $sourceImg->height;
    my $dest_width = 1024;
    my $dest_height = 768;

    if($source_width < $source_height) {
        $dest_width = 768;
        $dest_height = 1024;
    }

    my $destImg = GD::Image->new($dest_width, $dest_height);
    $destImg->copyResampled($sourceImg,
        0,  # dest x
        0,  # dest y
        0,  # source x
        0,  # source y
        $dest_width,   # dest width
        $dest_height,    # dest heigh
        $source_width,  # source width
        $source_height, # source height
    );
    my $file_content = encode_base64($destImg->jpeg());

    $self->app->insert_picture($file_content, $epoch, $dest_width, $dest_height);

    $self->redirect_to("/session/$epoch");
}


1;
