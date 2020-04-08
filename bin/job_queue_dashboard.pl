#!/usr/bin/env perl

use Mojolicious::Lite -signatures;

plugin Minion => { SQLite => 'sqlite:test.db' };
plugin 'Minion::Admin' => { 
    route => app->routes->any('/'),
};

app->start;
