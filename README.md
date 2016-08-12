# NAME

Badge::Depot::App - Mojo app for hosting some badges

# VERSION

Version 0.0017, released 2016-08-12.

# SYNOPSIS

    $ cpanm Badge::Depot::App
    $ badge-depot-app initdb
    $ hypnotoad path/to/badge-depot-app

# DESCRIPTION

`badge-depot-app` is a [Mojolicious](https://metacpan.org/pod/Mojolicious) application for hosting a few [Badge::Depot](https://metacpan.org/pod/Badge::Depot) badges. An instance is running at
[https://badgedepot.code301.com](https://badgedepot.code301.com). It is only necessary to run this application if you wish to host your own badges.

It uses a SQLite database to cache information fetched from data sources.

# COMMANDS

## initdb

    $ badge-depot-app initdb

This command creates the data directory (by using `my_dist_data` in [File::HomeDir](https://metacpan.org/pod/File::HomeDir)) where the database and configuration
files are stored.

To re-create the database (for instance after an incompatible upgrade):

    $ badge-depot-app initdb --force

# HOSTED BADGES

The following badges are hosted by this application:

- [Badge::Depot::App::Plugin::Badge::Cpantesters](https://metacpan.org/pod/Badge::Depot::App::Plugin::Badge::Cpantesters)
- [Badge::Depot::App::Plugin::Badge::Kwalitee](https://metacpan.org/pod/Badge::Depot::App::Plugin::Badge::Kwalitee)

# SEE ALSO

- [Badge::Depot](https://metacpan.org/pod/Badge::Depot)
- [Task::Badge::Depot](https://metacpan.org/pod/Task::Badge::Depot)
- [Pod::Weaver::Section::Badges](https://metacpan.org/pod/Pod::Weaver::Section::Badges)

# AUTHOR

Erik Carlsson <info@code301.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
