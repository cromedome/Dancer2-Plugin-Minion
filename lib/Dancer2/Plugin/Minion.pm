package Dancer2::Plugin::Minion;

use Dancer2::Plugin;
use Minion;

our $VERSION = '0.1.0';

plugin_keywords qw(
    minion
    add_task
    enqueue
);

has _backend => (
    is          => 'ro',
    from_config => 'backend',
    default     => sub{ '' },
);

has _dsn => (
    is          => 'ro',
    from_config => 'dsn',
    default     => sub{ '' },
);

has 'minion' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        Minion->new( $_[0]->_backend => $_[0]->_dsn );
    },
);

sub add_task {
    return $_[0]->minion->add_task( @_ );
}

sub enqueue {
    return $_[0]->minion->enqueue( $_[1] );
}

1;
__END__

=pod

=head1 NAME

Dancer2::Plugin::Minion - Easy access to Minion job queue in your Dancer2 
applications

=head1 SYNOPSIS

    use Clearbuilt::JobQueue;

    # Somewhere in your code....
    my $runner = Clearbuilt::JobQueue->new->runner;

    # $runner is an object of type Minion
    $runner->add_task( yarn_reconcile_import => sub( $job, $args {
        # Do something long
        $job->note(
            # Insert some metadata here...
        );
    });

    # Later in the code...
    $runner->run_job({
        name     => "yarn_reconcile_import",
        project  => 'efab',
        title    => "Yarn Reconcile Import",
        queue    => 'efab',
        job_args => [ 1, 2, 3 ],
    });

=head1 DESCRIPTION

C<Dancer2::Plugin::Minion> makes it easy to add a job queue to any of your
L<Dancer2> applications. The queue is powered by L<Minion> and uses a 
backend of your choosing, such as PostgreSQL or SQLite.

The plugin lazily instantiates a Minion object, which is accessible via the
C<minion> keyword. Any method, attribute, or event you need in Minion is 
available via this keyword. Additionally, C<add_task> and C<enqueue> keywords
are available to make it convenient to add and start new queued jobs.

See the L<Minion> documentation for more complete documentation on the methods
and functionality available.

=head1 ATTRIBUTES

=head2 runner

The L<Minion>-based object. See the L<Minion> documentation for a list of
additional methods provided.

=head1 METHODS

=head2 run_job()

Run a defined job in the job queue, and configure that job the way we are
accustomed to seeing them. This includes how it gets logged and how the 
process gets named. Takes a hashref of the following parameters:

=over 4

=item * name

Name of the job to be run. This is name of the job previously C<enqueue()>d 
that we are running. Required.

=item * project

Name of the project this job is for. Project + environment + job name is 
transformed into the name that we pass into Minion. Required.

=item * queue

Optional. Named queue to insert the job into. Uses a default queue if none
is specified. If we aren't running in production, automatically creates
and uses a queue named for the current environment.

=item * title

The human-readable name of the job. Shows up in logs and dashboards. Defaults
to the job name.

=item * job_args

Arguments to the job we are running. Required if the job requires any.

=back

Requires a job name, and if the job requires any, job arguments.

=head1 SEE ALSO

=over 4

=item * L<Dancer2>

=item * L<Minion>

=back

=head1 AUTHOR

Jason A. Crome C< cromedome AT cpan DOT org >

=head1 ACKNOWLEDGEMENTS

I'd like to extend a hearty thanks to my employer, Clearbuild Technologies,
for giving me the necessary time and support for this module to come to
life.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2020, Clearbuilt Technologies.

This is free software; you can redistribute it and/or modify it under 
the same terms as the Perl 5 programming language system itself.

=cut

