use 5.10.0;
use strict;
use warnings;

package Badge::Depot::App::Plugin::DB;

# AUTHORITY
our $VERSION = '0.0011';

use Mojo::Base 'Mojolicious::Plugin';
use File::HomeDir qw/my_dist_data/;
use Mojo::SQLite;
use Path::Tiny;
use Try::Tiny;
use DateTime;
use List::Util qw/any/;

has 'sqlite';
has 'db';

sub register {
    my $self = shift;
    my $app = shift;
    my $conf = shift;


    my $data_dir;
    try {
        $data_dir = path(my_dist_data('Badge-Depot-App'));
    }
    catch {};

    if(!$data_dir) {
        warn "It appears you have no data directory. Run 'badge-depot-app initdb' to set it up";
        return;
    }

    my $dbfile = $data_dir->child('badge_depot_app.db');
    if(!$dbfile->exists) {
        warn "It appears you have no database. Run 'badge-depot-app initdb' to set it up";
        return;
    }

    $self->sqlite(Mojo::SQLite->new('sqlite:' . $dbfile->realpath));
    $self->db($self->sqlite->db);
    $app->helper(db => sub { $self });

    return $self;
}

sub get_value {
    my $self = shift;
    my $badge = shift;

    my $info = shift;
    my $init_expiry = $info->{'init_expiry'} || 'hours';
    $init_expiry = (any { $init_expiry eq $_ } qw/hours days weeks months/) ? $init_expiry : 'hours';
    my $dist = $info->{'dist'};
    my $version = $info->{'version'};
    my $current = $info->{'current'};

    my $now = DateTime->now->strftime('%Y-%m-%d %H:%M:%S');

    my $results = $self->db->query(q{
        SELECT value, color, earliest_change_at, change_unit
          FROM distribution
         WHERE badge = ?
           AND distname = ?
           AND version = ?}, $badge, $dist, $version);

    my $row = $results->hash;
    if($row) {
        # no check (too early)
        if($row->{'earliest_change_at'} gt $now) {
            return { value => $row->{'value'}, color => $row->{'color'} };
        }
        # check if changed
        else {
            my $refreshed = $current->($dist, $version);
            if(!defined $refreshed) {
                $refreshed = { value => 'unknown', color => 'lightgrey' };
            }

            my $value = $refreshed->{'value'};
            my $color = $refreshed->{'color'};

            my($earliest_change_at, $change_unit) = $self->get_earliest_change_at($row->{'value'}, $value, $row->{'change_unit'});
            $self->db->query(q{
                UPDATE distribution
                   SET value = ?,
                       color = ?,
                       changed_at = ?,
                       earliest_change_at = ?,
                       change_unit = ?
                 WHERE distname = ?
                   AND version = ?
                   AND badge = ?
                }, $value, $color, $now, $earliest_change_at, $change_unit, $dist, $version, $badge);
            return { value => $row->{'value'}, color => $row->{'color'} };
        }
    }
    # new dist+version+badge
    else {
        my $refreshed = $current->($dist, $version);
        if(!defined $refreshed) {
            $refreshed = { value => 'unknown', color => 'lightgrey' };
        }

        my $value = $refreshed->{'value'};
        my $color = $refreshed->{'color'};

        my($earliest_change_at, $change_unit) = $self->get_earliest_change_at(undef, $value, $init_expiry);

        $self->db->query(q{
            INSERT INTO distribution (distname, version, badge, value, color, created_at, changed_at, earliest_change_at, change_unit) values (?, ?, ?, ?, ?, ?, ?, ?, ?)},
                                      $dist, $version, $badge, $value, $color, $now, $now, $earliest_change_at, $change_unit
        );
        return { value => $value, color => $color };
    }
}

sub get_earliest_change_at {
    my $self = shift;
    my $previous_value = shift;
    my $current_value = shift;
    my $change_unit = shift;

    my @expiries = qw/hours days weeks months/;
    my($current_expiry_index) = grep { $expiries[$_] eq $change_unit } 0..$#expiries;
    my $next_expiry = $current_expiry_index == $#expiries ? $change_unit : $expiries[ $current_expiry_index + 1];

    my $actual_unit = !defined $previous_value          ? 'hours'
                    : $previous_value eq $current_value ? $next_expiry
                    :                                     'hours'
                    ;

    my $earliest_change_at = DateTime->now->add(
        $actual_unit eq 'hours'  ? (hours => 12)
      : $actual_unit eq 'days'   ? (days => 2)
      : $actual_unit eq 'weeks'  ? (weeks => 2)
      : $actual_unit eq 'months' ? (months => 3)
      :                            (hours => 12)
    )->strftime('%Y-%m-%d %H:%M:%S');

    return ($earliest_change_at, $actual_unit);

}

1;

__END__
