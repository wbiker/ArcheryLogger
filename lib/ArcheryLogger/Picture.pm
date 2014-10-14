package ArcheryLogger::Picture;
use Mojo::Base 'Mojolicious::Controller';
use Data::Printer;
use Time::Moment;
use Digest::MD5 qw(md5_hex);
use MIME::Base64 qw(encode_base64);
use GD;
use GD::Image;
use File::Spec::Functions qw(catfile catdir);

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
    my $pic_path = $self->app->config('picture_path');
    my $time = Time::Moment->from_epoch($epoch);
    my $path_to_store_pic = $time->year.$time->month.$time->day_of_month;
    my $pfad = catdir($pic_path, $path_to_store_pic);
    mkdir($pfad) unless -e $pfad;
    my $hex_file_name = md5_hex($file_content);
    my $file_path = catfile($pfad, $hex_file_name);
    open(my $fh, ">", $file_path);
    print $fh $file_content;
    close($fh);
    
    $self->app->insert_picture($file_path, $epoch, $dest_width, $dest_height);

    $self->redirect_to("/session/$epoch");
}

sub list_pictures {
    my $self = shift;

    my $pics = $self->app->get_all_pictures();
    $self->stash(pics => $pics);
}

1;
