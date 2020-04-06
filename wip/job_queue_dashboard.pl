#!/usr/local/perl-efab/bin/perl

#
# To start in development:
# morbo bin/job_queue_dashboard.pl
#
# To start in production:
# hypnotoad bin/job_queue_dashboard.pl
#

use Mojolicious::Lite -signatures;

my $minions = plugin 'yaml_config' => { file => "../environments/minions.yml" };

plugin Minion => { Pg => $minions->{ dsn } };

plugin 'Minion::Admin' => { 
    return_to => $minions->{ dashboard_return_url },
    route     => app->routes->any('/'),
};

app->config( hypnotoad => { 
    listen   => [ 'http://*:' . $minions->{ dashboard_port } ],
    #pid_file => $minions->{ dashboard_pid },
});
app->start;
