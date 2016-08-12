use 5.10.0;
use strict;
use warnings;

package Badge::Depot::App;

# ABSTRACT: Mojo app for hosting some badges
# AUTHORITY
our $VERSION = '0.0018';

1;

__END__

=pod

=head1 SYNOPSIS

    $ cpanm Badge::Depot::App
    $ badge-depot-app initdb
    $ hypnotoad path/to/badge-depot-app

=head1 DESCRIPTION

C<badge-depot-app> is a L<Mojolicious> application for hosting a few L<Badge::Depot> badges. An instance is running at
L<https://badgedepot.code301.com>. It is only necessary to run this application if you wish to host your own badges.

It uses a SQLite database to cache information fetched from data sources.

=head1 COMMANDS

=head2 initdb

    $ badge-depot-app initdb

This command creates the data directory (by using C<my_dist_data> in L<File::HomeDir>) where the database and configuration
files are stored.

To re-create the database (for instance after an incompatible upgrade):

    $ badge-depot-app initdb --force

=head1 HOSTED BADGES

The following badges are hosted by this application:

=for :list
* L<Badge::Depot::App::Plugin::Badge::Cpantesters>
* L<Badge::Depot::App::Plugin::Badge::Kwalitee>

=head1 SEE ALSO

=for :list
* L<Badge::Depot>
* L<Task::Badge::Depot>
* L<Pod::Weaver::Section::Badges>

=cut
