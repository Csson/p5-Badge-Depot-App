use 5.10.0;
use strict;
use warnings;

package Badge::Depot::App::Command::initdb;

# AUTHORITY
our $VERSION = '0.0005';

use Mojo::Base 'Mojolicious::Command';
use Getopt::Long qw/GetOptionsFromArray/;
use File::HomeDir qw/my_dist_data/;
use Path::Tiny;
use Try::Tiny;
use Mojo::SQLite;
use String::Random;

sub run {
    my $self = shift;
    my $args = \@_;

    my $force = 0;
    GetOptionsFromArray $args, 'f|force' => \$force;

    my $data_dir;
    try {
        $data_dir = path(my_dist_data('Badge-Depot-App'));
    }
    catch {
        $data_dir = path(my_dist_data('Badge-Depot-App', { create => 1 }));
        $data_dir->child('mojo.secrets')->spew(String::Random->randpattern('c' x 40));
        $data_dir->child('mojo.conf')->spew({ hypnotoad => {} });
        say "Created data directory for Badge-Depot-App";
    };

    my $db = $data_dir->child('badge_depot_app.db');

    if($db->exists && !$force) {
        die sprintf 'The database exists at %s: Use --force to overwrite', $db->realpath;
    }
    if($db->exists) {
        $db->remove;
        say sprintf 'Has removed %s', $db->realpath;
    }

    my $sqlite = Mojo::SQLite->new('sqlite:' . $db->realpath);

    $sqlite->db->query(q{
        CREATE TABLE distribution (
            dist_id INTEGER PRIMARY KEY AUTOINCREMENT,
            distname TEXT NOT NULL,
            version TEXT NOT NULL,
            badge TEXT NOT NULL,
            value TEXT NOT NULL,
            color TEXT NOT NULL,
            created_at TEXT NOT NULL,
            changed_at TEXT NOT NULL,
            earliest_change_at TEXT NOT NULL,
            change_unit TEXT NOT NULL
        )
    });
    say sprintf 'Has created %s', $db->realpath;

}

1;

__END__
