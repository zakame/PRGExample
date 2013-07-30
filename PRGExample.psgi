#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use v5.14;
use Amon2::Lite;
use File::Basename;
use File::Spec;

{

    package PRGExample::Model;
    use parent 'Teng';

    sub insert_post {
        my ( $self, $name, $message ) = @_;
        return $self->insert(
            posts => { name => $name, message => $message } );
    }

    sub get_all_posts {
        return shift->search( posts => {} );
    }

    package PRGExample::Model::Schema;
    use Teng::Schema::Declare;

    table {
        name 'posts';
        pk 'id';
        columns qw( name message );
    };

}

my $postsdb = File::Spec->catfile( dirname(__FILE__), 'posts.db' );
my $posts = PRGExample::Model->new(
    { connect_info => ["dbi:SQLite:dbname=$postsdb"] } );

=for later

if ( @ARGV and my $arg = ( shift =~ /db-create/ ) ) {
    $posts->do(<<SQL);
CREATE TABLE posts (
    id      INTEGER PRIMARY KEY AUTOINCREMENT,
    name    TEXT,
    message TEXT
);
SQL
    say "db-create called!";
    exit 0;
}

=cut

get '/' => sub {
    return shift->render('form.tt');
};

# this is a post/redirect/get example
post '/post' => sub {
    my $c = shift;
    my $p = $c->req->parameters->mixed;

    if ( $p->{name} and $p->{message} ) {
        $c->session->set( post_success => 1 )
            if $posts->insert_post( $p->{name}, $p->{message} );
    }

    return $c->redirect('/messages');
};

get '/messages' => sub {
    my $c = shift;
    my $s = $c->session;

    my $success = $s->get('post_success');
    $s->remove('post_success') if $success;

    my @posts = $posts->get_all_posts;

    return $c->render( 'messages.tt',
        { posts => \@posts, success => $success } );
};

__PACKAGE__->template_options( cache => 0 );
__PACKAGE__->enable_session;
__PACKAGE__->to_app;

__DATA__

@@ messages.tt
[% WRAPPER "layout.tt" %]
<h2>Guestbook Messages</h2>
[% IF success -%]
<div class="alert alert-success">
  <button class="close" data-dismiss="alert" type="button">×</button>
  <strong>Good work.</strong> Post is most successful!
</div>
[% END -%]
[% IF posts.size() -%]
<p class="lead">This is what I got:</p>
  <ol>
[% FOR post IN posts -%]
    <li>
      <blockquote>
        [% post.message %]
        <small class="pull-right">Some person named <cite title="[% post.name %]">[% post.name %]</cite></small>
      </blockquote>
    </li>
[% END -%]
  </ol>
[% ELSE -%]
<p class="lead text-info">Nobody left a message.</p>
<p>Sad face.</p>
[% END -%]
[% END %]

@@ form.tt
[% WRAPPER "layout.tt" %]
<h2>Guestbook <small>leave a message...</small></h2>
<p class="lead">Here is an example of <a href="http://en.wikipedia.org/wiki/Post/Redirect/Get">Post/Redirect/Get</a>.</p>
<p>Fill in this form & stumbit it!</p>
<form method="post" action="[% uri_for('/post') %]" data-validate="parsley" novalidate>
  <fieldset>
    <legend>Post something already!!</legend>
    <label for="name">Name</label>
    <input type="text" id="name" name="name" placeholder="Give me your name..." required>
    <label for="message">Message</label>
    <textarea rows="5" id="message" name="message" placeholder="Post something..." required></textarea>
    <span class="help-block">It does not matter what you post, just do it!</span>
    <button type="submit" class="btn btn-primary">Stumbit!</button>
    <button type="reset" class="btn">Reset</button>
  </fieldset>
</form>
[% END %]

@@ layout.tt
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Post/Redirect/Get Example</title>
    <link href="http://twitter.github.io/bootstrap/assets/css/bootstrap.css" rel="stylesheet">
    <link href="http://twitter.github.io/bootstrap/assets/css/bootstrap-responsive.css" rel="stylesheet">
  </head>
  <body>
    <div class="page-header">
      <h1>Post/Redirect/Get Example <small>an Amon2::Lite demo</small></h1>
    </div>
    <div class="container-fluid">
      <div class="row-fluid">
        <div class="span2">
          <!-- sidebar -->
          <ul class="well nav nav-list">
            <li class="nav-header">Guestbook</li>
            <li><a href="[% uri_for('/') %]">Home</a></li>
            <li><a href="[% uri_for('/messages') %]">Messages</a></li>
            <li class="divider"></li>
            <li><a href="http://amon.64p.org">Amon2</a></li>
            <li><a href="http://zakame.net">Zakame.Net</a></li>
          </ul>
        </div>
        <div class="span10">
          <!-- body content -->
          [% content %]
        </div>
      </div>
      <footer>
        <p class="text-right">© Zakame 2013</p>
      </footer>
    </div>
    <script src="http://code.jquery.com/jquery.min.js"></script>
    <script src="http://parsleyjs.org/parsley.js"></script>
    <script src="http://twitter.github.io/bootstrap/assets/js/bootstrap.min.js"></script>
  </body>
</html>

__END__
