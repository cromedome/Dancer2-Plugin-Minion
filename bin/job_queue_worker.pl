#!/usr/local/perl-efab/bin/perl

use FindBin;
use lib "$FindBin::Bin/../lib";

use v5.24;
use Dancer2;
use Dancer2::Plugin::DBIC;
use Clearbuilt::Config;
use Clearbuilt::JobQueue;

my $minion = Clearbuilt::JobQueue->new;

##
## DEFINE JOBS FOR THIS PROJECT
##
$minion->runner->add_task( yarn_reconcile_import => sub {
    my( $job, @args ) = @_;
    
    my $id    = $job->id;
    my $notes = $job->info->{ notes };
    my $title = $notes->{ title };

    my ( $serial_num, $username ) = @args;
    $job->app->log->info("$title: Job $id is processing $serial_num");

    my $result;
    schema->txn_do(
        sub {
            my $job_rs = rset( 'Job' )->find( { serial_number => $serial_num } );
            die 'job not found' unless ( $job_rs && $job_rs->name eq 'yarn_reconcile job' );

            $result = rset('Transaction')->resolve_pending_transactions( $job_rs );
        },{
            user        => $username,
            description => 'yarn_reconcile resolve pending',
        } 
    );
    
    $job->finish( $result );
});

##
## CONFIGURE THE WORKER
##
my $worker = $minion->runner->worker;

$worker->on( dequeue => sub {
    my ( $worker, $job ) = @_;
    my $id    = $job->id;
    my $notes = $job->info->{ notes };
    my $title = $notes->{ title };

    $job->app->log->info("$title: Received job $id");

    $job->on( spawn => sub {  
        my ( $job, $pid ) = @_;
        say "$title: Created child process $pid for job $id by parent $$";
    });
    
    $job->on( failed => sub {
        my ( $job, $error ) = @_;
        chomp $error;

        my $id    = $job->id;
        my $notes = $job->info->{ notes };
        my $queue = $job->info->{ queue };
        
        $job->app->log->error( "$title: An error occurred in queue $queue:\n$error" );
    });

    $job->on(finish => sub {
        my $job   = shift;
        my $id    = $job->id;
        my $notes = $job->info->{ notes };
        my $queue = $job->info->{ queue };

        $job->app->log->info("$title: Job $id is finished processing in queue $queue.");
    });
});

$worker->on( busy => sub {
    my $worker = shift;
    my $max    = $worker->status->{ jobs };
    say "$0: Running at capacity (performing $max jobs).";
});

my $hostconfig = $minion->get_hostconfig();
my $max_jobs   = $hostconfig->{ max_children };

# Set up queues for dev or production
my @queues;
if( $minion->get_environment eq 'production' ) {
   @queues = @{ $hostconfig->{ queues }};
} else {
   push @queues, $minion->get_environment if $minion->get_environment ne 'production';
}

if( $minion->has_invalid_queues( @queues ) ){
    print "Invalid job queues specified: " . join( ',', $minion->get_invalid_queues( @queues ) );
    say ". Aborting!";
    exit 1;
}

##
## START THE WORKER
##
say "Starting Job Queue Worker on " . $minion->get_hostname();
say "- Configured to run a max of $max_jobs jobs";
say "- Listening for jobs on queues: ", join(', ', @queues );
$worker->status->{ jobs }   = $max_jobs;
$worker->status->{ queues } = \@queues;
$worker->run;
