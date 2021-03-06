use 5.10.0;
use strict;
use warnings;

package Badge::Depot::App::Plugin::Badge::Cpantesters;

# AUTHORITY
our $VERSION = '0.0018';

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::JSON qw/encode_json/;
use Mojo::UserAgent;
use Try::Tiny;
use CPAN::Testers::WWW::Reports::Parser;
use version;
use Safe::Isa qw/$_isa/;
use List::Util qw/sum/;
use URL::Encode qw/url_encode/;

sub register {
    my $self = shift;
    my $app = shift;
    my $conf = shift;

    $app->routes->get('/badge/cpantesters/:dist/*version', sub {
        my $c = shift;
        (my $dist = $c->param('dist')) =~ s{::}{-}g;
        my $version = $c->param('version');

        my $current = $app->db->get_value('cpantesters', {
            init_expiry => 'hours',
            dist => $dist,
            version => $version,
            current => $self->current,
        });

        $app->render_badge($c, 'cpantesters', $current->{'value'}, $current->{'color'});
    });

    return $app;
}

sub current {
    my $self = shift;

    return sub {
        my $info = shift;
        my $dist = $info->{'dist'};
        my $version = $info->{'version'};
        my $first_letter = substr $dist, 0, 1;

        my $json = Mojo::UserAgent->new->get("http://www.cpantesters.org/distro/$first_letter/$dist.json")->res->json;
        return if !defined $json;

        my $report;
        try {
            $report = CPAN::Testers::WWW::Reports::Parser->new(
                format => 'JSON',
                objects => 1,
                data => encode_json($json),
            );
        }
        catch { };
        return if !defined $report;

        if($version eq 'latest') {
            my $latest_version;
            while(my $data = $report->report) {
                my $report_version = version->new($data->version);

                $latest_version = $report_version if !defined $latest_version;
                $latest_version = $report_version if $report_version > $latest_version;
            }
            $version = $latest_version;
        }
        return if !defined $version || $version eq 'latest';
        $version = version->new($version) if !$version->$_isa('version');

        my %stats = (
            PASS => 0,
            NA => 0,
            UNKNOWN => 0,
            INVALID => 0,
            FAIL => 0,
        );

        while(my $data = $report->report) {
            next if version->parse($data->version) != $version;
            ++$stats{ $data->status };
        }

        return if sum(values %stats) == 0;

        my $ok = $stats{'PASS'};
        my $fails = $stats{'FAIL'};
        my $na = $stats{'NA'};
        my $unknowns = $stats{'NA'} + $stats{'UNKNOWN'} + $stats{'INVALID'};

        # NA doesn't count towards the color
        my $percent = 100 * $ok / ($ok + $fails + $stats{'UNKNOWN'} + $stats{'INVALID'});

        my $color = $percent >= 99   ? 'brightgreen'
                  : $percent >= 97.5 ? 'green'
                  : $percent >= 95   ? 'yellowgreen'
                  : $percent >= 90   ? 'yellow'
                  : $percent >= 80   ? 'orange'
                  :                    'red'
                  ;

        return { value => "$ok / $unknowns / $fails", color => $color };

    };
}

1;

__END__
