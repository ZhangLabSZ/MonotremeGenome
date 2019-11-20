##
## Parse newick or nhx format tree string to hash tree;
## 
## Original author(Maybe): Li Heng, Fan Wei, etc.
## Created on: 2006-3-28
##
## Updated by: Wang Zhuo, wangzhuo@genomics.org.cn
## Version 1.0, Last change: 2010-11-15
##


## Updates:
## - 2010-11-15, 
##   rewrite some of the codes to make it easily be read;
##   add more comments on codes implements;
##
##


package Tree::nhx_core;
use strict;
use Data::Dumper;

use vars qw($VERSION @ISA @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter);

$VERSION = "1.0";
@EXPORT_OK = qw(
	new root nodes nodes_arr
	parse string
	set_outgroup remove_root sort_nodes add_root
	get_leaf_names

	traverse preorder postorder 
	nhx_str2arr nhx_arr2hash nhx_hash2arr nhx_arr2str
	hash2arr get_nhx_str
);


## Creat a new tree object;
sub new
{	
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;
	my $self = {
		_root => undef,
		_id_count => undef,
		_nodes => undef,
		_nodes_arr => undef,
		_error => undef,
		@_ 
	};
	bless($self, $class);
	return $self;
}

## Return a reference to root node(node is a hash);
sub root {
	my $self = shift;
	return $self->{_root};
}

## Return a reference to array of all nodes(each node is a hash);
##   traversing binary tree in this order: left, right, middle,
##   to create the array containing all nodes;
## 
## For each hash node:
##   id => taxon or internal node id;
##   name => taxon name or internal node names;
##   supp => supp information;
##   brlen => branch length;
##   parent => ref to the parent node;
##   child => array of children nodes;
## And other nhx-specific items;
##
sub nodes {
	my $self = shift;
	return @{$self->{_nodes}};
}

## Return a reference to array of all original nodes
## (each node is a array, all brackets/taxon are nodes);
##   0 -> type: LEFT, TAXON, RIGHT;
##   1 -> layer: start from 0, and auto-increase;
##   2 -> name: taxon name;
##   3 -> supp_info: supplymentary info of internal nodes;
##   4 -> brlen: branch length;
##   5 -> nhx_info: nhx information;
##
sub nodes_arr {
	my $self = shift;
	return @{$self->{_nodes_arr}};
}

## When providing a ref to root, traverse binary-tree, push hash-nodes to array;
## two types of traversal is supported: preorder, postorder;
## and another traversal option: hash2arr;
sub traverse {
	my ($self, $root_node, $type) = @_;

	my @nodes;
	if ($type eq "preorder") {
		$self->preorder($root_node, \@nodes);
	}
	elsif ($type eq "postorder") {
		$self->postorder($root_node, \@nodes);
	}
	elsif ($type eq "hash2arr") {
		$self->hash2arr($root_node, \@nodes, 0);
	}
	return \@nodes;
}

sub preorder {
	my ($self, $tmp, $a_nodes) = @_;

	push @$a_nodes, $tmp;
	return if (!defined $tmp->{child});
	foreach my $c (@{$tmp->{child}}) {
		$self->preorder($c, $a_nodes);
	}
}

sub postorder {
	my ($self, $tmp, $a_nodes) = @_;

	return if (!defined $tmp->{child});
	foreach my $c (@{$tmp->{child}}) {
		$self->postorder($c, $a_nodes);
	}
	push @$a_nodes, $tmp;
}

sub hash2arr {
	my ($self, $tmp, $a_nodes, $layer) = @_;

	if (!defined $tmp->{child}) {
		push @$a_nodes, 
			["TAXON", $layer, $tmp->{name}, "", $tmp->{brlen}, $self->get_nhx_str($tmp)];
		return;
	}

	push @$a_nodes, 
		["LEFT", $layer, "", $tmp->{supp}, $tmp->{brlen}, $self->get_nhx_str($tmp)];
	foreach my $c (@{$tmp->{child}}) {
		$self->hash2arr($c, $a_nodes, $layer+1);
	}
	push @$a_nodes, 
		["RIGHT", $layer, "", $tmp->{supp}, $tmp->{brlen}, $self->get_nhx_str($tmp)];
}

sub get_nhx_str {
	my ($self, $h_tmp) = @_;
	my $str = "";
	return $str if (!defined $h_tmp->{child});

	foreach (keys %$h_tmp) {
		next if ($_ eq "supp" || $_ eq "brlen" || $_ eq "parent" 
			|| $_ eq "child" || $_ eq "name" || $_ eq "id");
		$str .= ":$_=$h_tmp->{$_}";
	}
	$str = "\[&&NHX$str\]" if ($str ne "");
	return $str;
}

## Trim blank characters at the beginning and ending of string;
sub trim {
	my $self = shift;
	s/^\s+|\s+$//g foreach (@_);
}

## parse newick or nhx format tree string into two dimensional tree array;
## i.e. parse $tree_str to $self->{_nodes_arr};
##
sub nhx_str2arr
{
	my ($self, $tree_str) = @_;
	$tree_str .= ";" if ($tree_str !~ /;$/);

	my @nodes_arr;
	my $name_re = '[^\[\:\,\)]+';
	my $brlen_re = '[\d\.\s]*';
	my $nhx_re = '\[[^\[\]]*\]';
	my $layer = 0;
	my $i = 0;
	while (length($tree_str) > 0) {
		if ($tree_str =~ /^\(/) {
			$tree_str =~ s/^\(//;
			push @nodes_arr, ["LEFT", $layer, "", "", "", ""];
			$layer++;
		}
		elsif ($tree_str =~ /^($name_re)(:($brlen_re))?($nhx_re)?([\s,\);]+[\s\S]*)/) {
			my ($name, $brstr, $brlen, $nhx_info) = ($1, $2, $3, $4);
			#$tree_str =~ s/^$name$brstr$nhx_info//;
			$tree_str = $5;
			$tree_str =~ s/^\s+//;
			$self->trim($name, $brlen, $nhx_info);
			push @nodes_arr, 
				["TAXON", $layer, $name, "", $brlen, $nhx_info];
		}
		elsif ($tree_str =~ /^([^\w\(\)]+)/) {
			$tree_str =~ s/^$1//;
		}
		elsif ($tree_str =~ /^\)($name_re)?(:($brlen_re))?($nhx_re)?([\s,\);]+[\s\S]*)/) {
			my ($supp_info, $brstr, $brlen, $nhx_info) = ($1, $2, $3, $4);
			#$tree_str =~ s/^\)$supp_info$brstr$nhx_info//;
			$tree_str = $5;
			$tree_str =~ s/^\s+//;
			$layer--;
			$self->trim($supp_info, $brlen, $nhx_info);
			push @nodes_arr, 
				["RIGHT", $layer, "", $supp_info, $brlen, $nhx_info];
		}
	}
	@{$self->{_nodes_arr}} = @nodes_arr;
	return @nodes_arr;
}

## parse two dimensional array to hash tree;
## i.e. parse $self->{_nodes_arr} to $self->{_nodes};
##
sub nhx_arr2hash
{
	my ($self) = @_;

	my @stack;  # stack of hash nodes;
	foreach my $a (@{$self->{_nodes_arr}})
	{
		if ($a->[0] eq "LEFT") 
		{ push @stack, "("; next; }

		my %hash;
		$hash{id} = ++$self->{_id_count};
		$hash{name} = $a->[2];
		$hash{supp} = $a->[3];
		$hash{brlen} = $a->[4];
		$a->[5] =~ s/:([^=:]+)=([^:=\[\]]+)/$hash{$1}=$2,''/eg;

		if ($a->[0] eq "TAXON") {
			$hash{child} = undef;
		}
		elsif ($a->[0] eq "RIGHT") {
			my (@tmp, $b);
			while ($b = pop @stack) {
				last if (ref($b) ne "HASH");
				push @tmp, $b;
			}
			@tmp = reverse @tmp; # the same order as input tree string;
			foreach (@tmp) {
				push @{$hash{child}}, $_;
				$_->{parent} = \%hash;
			}
		}
		push @stack, \%hash;
	}
	$self->{_root} = pop @stack;
	$self->{_nodes} = $self->traverse($self->{_root}, "preorder"); # preorder, postorder;
	return %{$self->{_root}};
}

## parse hash tree to two dimensional array;
## i.e. parse $self->{_nodes} to $self->{_nodes_arr};
##
sub nhx_hash2arr {
	my ($self) = @_;
	$self->{_nodes_arr} = $self->traverse($self->{_root}, "hash2arr");
	return @{$self->{_nodes_arr}};
}

## parse two dimensional tree array into newick or nhx format tree string;
## i.e. parse $self->{_nodes_arr} to $tree_str;
##
sub nhx_arr2str {
	my ($self) = @_;

	my $str;
	foreach my $n (@{$self->{_nodes_arr}}) {
		if ($n->[0] eq "LEFT") {
			$str .= "(";
		}
		elsif ($n->[0] eq "TAXON") {
			$str .= $n->[2];
			$str .= ":$n->[4]" if ($n->[4] ne "");
			$str .= ",";
		}
		elsif ($n->[0] eq "RIGHT") {
			$str =~ s/,+$//g;
			$str .= ")$n->[3]";
			$str .= ":$n->[4]" if ($n->[4] ne "");
			$str .= "$n->[5]" if ($n->[5] ne "");
			$str .= ",";
		}
	}
	$str =~ s/,+$//g;
	$str .= ";";
	return $str;
}

## parse string to hash tree;
## 
sub parse {
	my ($self, $str) = @_;
	$self->nhx_str2arr($str);
	return $self->nhx_arr2hash();
}

## parse hash tree to string;
## 
sub string {
	my $self = shift;
	$self->nhx_hash2arr();
	return $self->nhx_arr2str();
}

## set outgroup taxon for hash tree;
## 
sub set_outgroup {
	my ($self, $taxon) = @_;
	$self->remove_root();

	my ($outgrp_node, $new_root);
	foreach my $p ($self->nodes)
	{
		if ($p->{name} eq $taxon) {
			$outgrp_node = $p->{parent};
			$new_root = $p->{parent};
		}
	}

	my ($last_node, $next_node, $curr_node, %last_values);
	$curr_node = $outgrp_node;

	while (1) {
		my %tmp_values;
		foreach (keys %{$curr_node}) {
			next if ($_ eq "id" || $_ eq "name" || $_ eq "parent" || $_ eq "child");
			$tmp_values{$_} = $curr_node->{$_};
		}

		## Delete child of current node;
		if (defined $last_node) {
			my @new_children;
			foreach (@{$curr_node->{child}}) {
				next if ($_->{id} eq $last_node->{id});
				push @new_children, $_;
			}
			@{$curr_node->{child}} = @new_children;
		}

		## Adjust parent to child, child to parent of current node;
		if (defined $curr_node->{parent}) {
			$next_node = $curr_node->{parent};
			push @{$curr_node->{child}}, $next_node;
			$curr_node->{parent} = $last_node;
			foreach (keys %{$curr_node}, keys %last_values) {
				next if ($_ eq "id" || $_ eq "name" || $_ eq "parent" || $_ eq "child");
				if (exists $last_values{$_}) {
					$curr_node->{$_} = $last_values{$_};
				}
				else { delete $curr_node->{$_}; }
			}
		}
		else { 
			$curr_node->{parent} = $last_node;
			foreach (keys %{$curr_node}, keys %last_values) {
				next if ($_ eq "id" || $_ eq "name" || $_ eq "parent" || $_ eq "child");
				if (exists $last_values{$_}) {
					$curr_node->{$_} = $last_values{$_};
				}
				else { delete $curr_node->{$_}; }
			}
			last; 
		}

		$last_node = $curr_node;
		%last_values = ();
		$last_values{$_} = $tmp_values{$_} foreach (keys %tmp_values); 
		$curr_node = $next_node;
		#print "$last_node->{id}, $curr_node->{id}, $next_node->{id}\n";
	}

	## Sort nodes by taxon names;
	$self->{_root} = $new_root;
	$self->sort_nodes($self->{_root}, "no", $taxon);

	$self->{_nodes} = $self->traverse($self->{_root}, "preorder"); # preorder, postorder;
	return %{$self->{_root}};
}

## add root of hash tree: change unrooted tree to rooted tree
##
sub add_root {
	my $self = shift;
	my @leaf = $self->get_leaf_names;
	my @child = @{$self->{_root}->{child}};
	return if(@leaf == 2 || @child != 3);

	my $left_p = $child[0];
	my $mid_p = $child[1];
	my $right_p = $child[2];

	my %hash;
	$hash{id} = ++$self->{_id_count};
	push @{$hash{child}}, $self->{_root};
	push @{$hash{child}}, $right_p;

	$right_p->{brlen} /= 2;
	$right_p->{parent} = \%hash;

	@{$self->{_root}->{child}} = ($left_p, $mid_p);
	$self->{_root}->{parent} = \%hash;
	$self->{_root}->{brlen} = $right_p->{brlen};

	$self->{_root} = \%hash;
	$self->{_nodes} = $self->traverse($self->{_root}, "preorder"); # preorder, postorder;
}

## remove root of hash tree: change rooted tree to unrooted tree
##
sub remove_root {
	my $self = shift;
	my @leaf = $self->get_leaf_names;
	my @child = @{$self->{_root}->{child}};
	return if(@leaf == 2 || @child != 2);

	my $left_p = $child[0];
	my $right_p = $child[1];

	$right_p->{brlen} += $left_p->{brlen};
	$right_p->{parent} = $left_p;

	push @{$left_p->{child}}, $right_p;
	foreach (keys %{$left_p}) {
		next if ($_ eq "id" || $_ eq "name" || $_ eq "child");
		delete $left_p->{$_};
	}
	$self->{_root} = $left_p;
	$self->{_nodes} = $self->traverse($self->{_root}, "preorder"); # preorder, postorder;
}


## Sort nodes by taxon name or id;
##
sub sort_nodes {
	my $self = shift;
	my ($p, $type, $outgrp_taxon) = @_;

	return if (!defined $p->{child} || @{$p->{child}} < 2);
	if ($type eq "name") {
		@{$p->{child}} = sort {$a->{name} cmp $b->{name}} @{$p->{child}};
	}
	if ($type eq "id") {
		@{$p->{child}} = sort {$a->{id} cmp $b->{id}} @{$p->{child}};
	}
	if ($outgrp_taxon ne "") {
		my (@new_children, $has_outgrp, $node_outgrp);
		foreach (@{$p->{child}}) {
			if ($_->{name} eq $outgrp_taxon) {
				$has_outgrp = 1;
				$node_outgrp = $_;
			}
			else {
				push @new_children, $_;
			}
		}
		if ($has_outgrp) {
			push @new_children, $node_outgrp;
			@{$p->{child}} = @new_children;
		}
	}

	foreach (@{$p->{child}}) {
		$self->sort_nodes($_, $type, $outgrp_taxon);
	}
}

## get leaf node names;
##
sub get_leaf_names {
	my $self = shift;
	my $tmproot = shift;
	$tmproot = $self->root if (!defined $tmproot);

	my @arr;
	my @tmpnodes;
	push @tmpnodes, $tmproot;
	while (@tmpnodes > 0) {
		my $p = shift @tmpnodes;
		if (defined $p->{name} && !$p->{child}) {
			push @arr, $p->{name};
		}
		elsif (@{$p->{child}} > 0) {
			push @tmpnodes, @{$p->{child}};
		}
	}
	return @arr;
}


1;

__END__

