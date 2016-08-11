use 5.10.0;
use strict;
use warnings;

package Badge::Depot::App::Plugin::Badge::Kwalitee;

# AUTHORITY
our $VERSION = '0.0015';

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::JSON qw/encode_json/;
use Mojo::UserAgent;

sub register {
    my $self = shift;
    my $app = shift;
    my $conf = shift;

    return $app->routes->get('/badge/kwalitee/:author/:dist/*version', sub {
        my $c = shift;
        (my $dist = $c->param('dist')) =~ s{::}{-}g;
        my $version = $c->param('version');
        my $author = $c->param('author');

        my $current = $app->db->get_value('kwalitee', {
            init_expiry => 'hours',
            dist => $dist,
            version => $version,
            author => $author,
            current => $self->current,
        });

        $app->render_badge($c, 'kwalitee', $current->{'value'}, $current->{'color'});

    });

    return $app;
}

sub current {
    my $self = shift;

    return sub {
        my $info = shift;
        my $dist = $info->{'dist'};
        my $version = $info->{'version'};
        my $author = $info->{'author'};

        my $tx = Mojo::UserAgent->new->get("http://cpants.cpanauthors.org/release/$author/$dist-$version.json");
warn "http://cpants.cpanauthors.org/release/$author/$dist-$version.json";
        if(!$tx->success) {
            return;
        }

        my $data = $tx->res->json;
        my $core_kwalitee = $data->{'distribution'}{'core_kwalitee'};
        my $kwalitee = $data->{'distribution'}{'kwalitee'};

        my $color = $core_kwalitee == 100 && $kwalitee > 130   ? 'brightgreen'
                  : $kwalitee >= 128                           ? 'green'
                  : $kwalitee >= 120                           ? 'yellow'
                  : $kwalitee >= 110                           ? 'orange'
                  :                                              'red'
                  ;
        return { value => sprintf ('%.2f' => $kwalitee), color => $color };
    };
}

1;

__END__
