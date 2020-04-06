package Clearbuilt::JobQueue;

use Moo;
use Minion;
use Carp qw( croak );
use List::Util qw( any );
use Sys::Hostname;
with 'Clearbuilt::Role::ConfigReader';
with 'Clearbuilt::Role::GetEnvironment';

my @VALID_QUEUES;

has 'runner' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $ENV{ MOJO_PUBSUB_EXPERIMENTAL } = 1;
        Minion->new( Pg => $self->_minion_config->{ dsn } );
    },
);

has _minion_config => (
    is      => 'ro',
    default => sub {
        my $self = shift;
        $self->load_config( 'environments/minions.yml' );
    },
);

sub BUILD {
    my $self = shift;

    @VALID_QUEUES = $self->_minion_config->{ valid_queues }->@*;
}

sub has_invalid_queues {
    my ( $self, @queues ) = @_;
    return 1 if $self->get_invalid_queues( @queues );
    return 0;
}

sub get_invalid_queues {
    my ( $self, @queues ) = @_;

    # If we aren't in production, push the environment name to the valid queue list
    push @VALID_QUEUES, $self->get_environment if $self->get_environment ne 'production';

    my %queue_map;
    @queue_map{ @VALID_QUEUES } = (); # Transform queue list into hash slice for easy lookup
    my @invalid_queues = grep !exists $queue_map{ $_ }, @queues;
    return @invalid_queues;
}

sub run_job {
    my ( $self, $args ) = @_;

    my $temp_name = $args->{ name     } or croak "run_job(): must define job name!";
    my $project   = $args->{ project  } or croak "run_job(): must define a project!";
    my $job_args  = $args->{ job_args };
    my $queue     = $self->_get_queue( $args->{ queue } );
    croak "run_job(): Invalid job queue '$queue' specified" if $self->has_invalid_queues( $queue );

    my $env      = $self->get_environment;
    my $job_name = "$project-$env-$temp_name";
    my $title    = $args->{ title } // $job_name;

    my %notes = ( 
        title   => $title,
        project => $project,
        env     => $env,
    );

    return $self->runner->enqueue( $temp_name => $job_args => { notes => \%notes, queue => $queue });
}

sub get_hostconfig {
    my $self = shift;

    my $minion_config = $self->_minion_config;
    my $hostname      = get_hostname();

    if( exists $minion_config->{ hosts }{ $hostname }) {
        return $minion_config->{ hosts }{ $hostname };
    } else {
        return $minion_config->{ default };
    }
}

sub get_hostname {
    my ($short_hostname) = split /\./, hostname();
    return $short_hostname;
}

sub _get_queue {
   my $self = shift;
   my $requested_queue = shift // 'default';

   if( $self->get_environment eq 'production' ) {
      return $requested_queue;
   } else {
      return $self->get_environment;
   }
}

1;

=pod

=head1 NAME

Clearbuilt::JobQueue - Easy access to Minion job queue in Clearbuilt applications

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

C<Clearbuilt::JobQueue> makes it easy to add a job queue to any of your
Clearbuilt applications. The queue is powered by L<Minion> and uses the
L<Minion::Backend::Pg> provider.

To create a job, you use the C<add_task()> method present on the runner. The
developer gives that job a name, which can then be used to invoke or monitor 
the job at a later time. Jobs can be created anywhere in your application,
so long as the runner has been instantiated.

Each job may have an unlimited amount of metadata associated with them. To add
metadata, use the C<notes> attribute present on the job.

See the L<Minion> documentation for more complete documentation on the methods
and functionality available.

=head1 ATTRIBUTES

=head2 runner

The L<Minion>-based object. See the L<Minion> documentation for a list of
additional methods provided.

=head1 METHODS

=head2 has_invalid_queues()

Checks the provided list of job queue names for validity. Takes a single queue
name or a list of names. Returns true if any of the provided queue names are
invalid, otherwise returns false.

=head2 get_hostname()

Get the short hostname of this box.

=head2 get_hostconfig()

Get the Minion configuration for this host.

=head2 get_invalid_queues()

Given a list of queue names (or, a singluar queue name), return the list of
queue names that are invalid.

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

=cut

1;
