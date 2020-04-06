package Clearbuilt::JobQueue::Utils;

use strict;
use warnings;
use Clearbuilt::JobQueue;

our ( @ISA, @EXPORT_OK, $MINION );

BEGIN {
   require Exporter;
   @ISA       = qw(Exporter);
   @EXPORT_OK = qw( add_job remove_job get_jobs job_types );
   $MINION    = Clearbuilt::JobQueue->new;
}

sub add_job {
    my $job_id   = shift;
    my $job_type = shift // 'default';
    my $job      = $MINION->runner->job( $job_id )
        or die "_add_job(): no such job id!";

    my @jobs = get_jobs();
    push @jobs, { job_id => $job_id, type => $job_type };

    return \@jobs;
}

sub remove_job {
    my $job_id = shift;
    my $job = $MINION->runner->job( $job_id )
        or die "_remove_job(): no such job id!";

    my @jobs = get_jobs();
    @jobs = grep{ $_->{ job_id } != $job_id  } @jobs;

    return \@jobs;
}

sub get_jobs {
    my $active_jobs = session->read( 'active_jobs' );
    my @jobs        = ref $active_jobs eq 'ARRAY' ? $active_jobs->@* : ();
    return @jobs;
}

sub job_types {
    my @job_types;
    push @job_types, { type => 'pricingimport', url => '/admin/reconcile_results/' };
    return \@job_types;
}

1;
