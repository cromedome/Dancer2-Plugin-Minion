package TestApp;

use Dancer2;
use Dancer2::Plugin::Minion;
use Data::Dumper;

get '/' => sub {
    add_task( foo => sub {
        print STDERR join( ', ', @_ ) . "\n";
    });

    return "OK - Task Added";
};

get '/start' => sub { 
    my $id = enqueue( foo => [ qw( Foo Bar Baz ) ] );
    minion->foreground( $id );
    return "OK - job started";
};
