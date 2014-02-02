#! /usr/bin/perl

use strict;
use Math::Random::Discrete;

my $nodes = {};
my $net   = {};
my $markup = {};

open MERW_HITS, ">> comm_walks_merw.log" || die "Err: cannot open MERW hits !\n";

open GERW_HITS, ">> comm_walks_rw.log" || die "Err: cannot open MERW hits !\n";

# Samples from discrete distribution in the form p1=0.1, p2=0.7,... using simple alias method
# Procedure to be employed in MERW
sub alias_sample
{
}

sub simple_rw
{
	my $net		= shift;
	my $markup	= shift;
	my $seed_node   = shift;
	my $max_steps   = 150;
	
	print GERW_HITS "\n (Node, Community): $seed_node\t $markup->{ $seed_node }\t";
	# Counts hits to the communities ( to compute various further metrics like entropy )
	my %comm_hits;
	foreach my $step (1..$max_steps)
	{
		my @out_edges = keys %{ $net->{ $seed_node }};	
		my $rand_id   = int( rand( $#out_edges ));

		my $new_node  = $out_edges[ $rand_id ];

		# In undirected graphs this will avoid waiting till the end of Universe
		if ( ++$step > $max_steps )
		{
			last;
		}
	
		$comm_hits{ $markup->{ $new_node } }++;
		$seed_node	= $new_node;

		print GERW_HITS " ".$markup->{ $new_node };
	}

	# Compute and return trace metric. It's highly likely, that entropy will do the trick. High entropy means fuzzier community hitting.
	open TRACES, ">> traces_gerw.log" || die "Err: cannot open traces!\n";
	print TRACES join(" , ", map { my $key = $_; qq($key => $comm_hits{ $key}) } map { $_->[0] } sort { $b->[1] <=> $a->[1]} map { [$_, $comm_hits{$_}] }   keys %comm_hits )."\n";
	close TRACES;

}

sub degree
{
	my $net  	 =  shift;
	my $seed_node    =  shift;

	my $degree = scalar keys %{ $net->{ $seed_node }};

	return $degree;
}

sub merw
{
	my $net		= shift;
	my $markup	= shift;
	my $seed_node   = shift;
	my $max_steps   = 150;
	

	print MERW_HITS "\n (Node, Community): $seed_node\t $markup->{ $seed_node }\t";
	# Counts hits to the communities ( to compute various further metrics like entropy )
	my %comm_hits;
	foreach my $step (1..$max_steps)
	{
		my @out_edges = keys %{ $net->{ $seed_node }};	

		my ( @Kn, @Knn );
		foreach my $nb ( @out_edges )
		{
			push @Kn, degree( $net, $nb );

			my @nb_edges = keys %{ $net->{ $nb }};
			my $deg_sum;
			map { $deg_sum += degree( $net,  $_ ) } @nb_edges;

			my $nn_avr     = $deg_sum/$#nb_edges;
			push @Knn, $nn_avr;
		}

		my @biases;
		foreach my $idx ( 1..$#out_edges )
		{
			push @biases, $Kn[ $idx ] * $Knn[ $idx ];
		}
		# TODO: use Math::Random::Discrete to sample from Kn*Knn!
		my $next_hop = Math::Random::Discrete->new( [ @biases ], [ (0..$#out_edges) ]);

		my $next_id  = $next_hop->rand;

		my $new_node	= $out_edges[ $next_id ];

		$comm_hits{ $markup->{ $new_node } }++;
		$seed_node	= $new_node;

		print MERW_HITS " ".$markup->{ $new_node };

	}

	# Compute and return trace metric. It's highly likely, that entropy will do the trick. High entropy means fuzzier community hitting.
	open TRACES, ">> traces_merw.log" || die "Err: cannot open traces!\n";
	print TRACES join(" , ", map { my $key = $_; qq($key => $comm_hits{ $key}) } map { $_->[0] } sort { $b->[1] <=> $a->[1]} map { [$_, $comm_hits{$_}] }   keys %comm_hits )."\n";
	close TRACES;
}


open EDGES, "< $ARGV[0]" || die "No edges\n";
open MARKUP, "< $ARGV[1]" || die "No markup\n";

while ( <EDGES> )
{
	chomp;

	my ( $s, $t ) = split("\t");

	if ( ! defined ( $nodes->{ $s }))
	{
		$nodes->{ $s } = 1;
	}

	if ( ! defined ( $nodes->{ $t }))
	{
		$nodes->{ $t } = 1;
	}

	$net->{ $s }->{ $t } = 1;
}

while ( <MARKUP> )
{
	chomp;

	my ( $id, $comm ) = split("\t");
	$markup->{$id}    = $comm;
}

# 1. Count how many times GERW and MERW hit the nodes inside communities

# First, GERW takes it's turn...

my @nodes = keys %{ $nodes };
for my $turn ( 1..500 )
{
		my $index = int( rand( $#nodes ));

		my $seed_node  = $nodes[ $index];
		my $community  = $markup->{ $seed_node };

		open TRACES, ">> traces.log" || die "Err: cannot open traces!\n";
		print TRACES	" (Seed node, community): $seed_node\t$community\t"; 
		close TRACES;


		print " (Seed node, community): $seed_node\t$community \n"; 
		simple_rw( $net, $markup, $nodes[ $index] );
}

# Now we test for MERW

for my $turn ( 1..500 )
{
		my $index = int( rand( $#nodes ));

		my $seed_node  = $nodes[ $index];
		my $community  = $markup->{ $seed_node };

		open TRACES, ">> traces_merw.log" || die "Err: cannot open traces!\n";
		print TRACES	" (Seed node, community): $seed_node\t$community\t"; 
		close TRACES;


		print "MERW (Seed node, community): $seed_node\t$community \n"; 
		merw( $net, $markup, $nodes[ $index] );
}
print "Eee haaa!\n";
