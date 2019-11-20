## parse nh or nhx format tree text
## Creat on: 2006-3-28

package Tree::nhx;
use strict;

## creat a new obejct, and set the parameters
sub new
{	
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;
	my $self = {
		_node=>undef,				_root=>undef,
		_n_leaf=>undef,				_error=>undef,
		@_ } ;
	bless($self, $class);
	return $self;
}


## return root pointer
sub root{
	my $self = shift;
	return $self->{_root};
}



## return leaf names
sub leaf{
	my $self = shift;
	my @ary;
	foreach my $p ($self->node) {
		push @ary, $p->{N} if(defined $p->{N} && !$p->{C});
	}
	return @ary;
}


## recursive order: left, right, middle
sub node{
	my $self = shift;
	return @{$self->{_node}};
}

## add atrributions to the tree according to node name
sub add_character{
	my $self = shift;
	my ($name, $hash) = @_ ;
	my $array=$self->{_node};
	
	foreach my $p (@$array) {
		$p->{$name} = $hash->{$p->{N}} if (defined $hash->{$p->{N}});
	}	
}


##output basic information of all the nodes
sub info{
	my $self=shift;
	my $output;
	
	my $star_line = '*' x 50;
	foreach my $p ($self->node) {
		$output .= "\n$star_line\n\n" ;
		foreach my $key (sort keys %$p) {
			my $val = $p->{$key};
			$output .=  "$key\t$val\n";
			
		}
	}
	return $output;
}

## sort the tree according to children number of each node
sub sort_tree{
	my $self = shift;
	foreach my $p ($self->branch) {
		if ($p->{C}) {
			my $first = $self->branch($p->{C}[0]);
			my $last  = $self->branch($p->{C}[-1]);
			if ( $first < $last ) {
				my $tp = $p->{C}[0];
				$p->{C}[0] = $p->{C}[-1];
				$p->{C}[-1] = $tp;
			}
			
		}
	}
}


##recursive order: middle,left,right
##when add tags, be alert to shift out root node as the first element;
sub branch{
	my $self=shift;
	my $root=(@_) ? shift : $self->{_root};	
	my @ary;
	$self->branch_aux($root,\@ary);
	return @ary;
}

sub branch_aux{
	my $self=shift;
	my $root=shift;	
	my $ary_p = shift;
	
	push @$ary_p,$root;
	
	## very,very,very important, for the leaf node should not have "C" hash-field
	return unless(defined $root->{C});
	
	foreach my $child_p (@{$root->{C}}) {
		$self->branch_aux($child_p,$ary_p);		
	}	
}


##change rooted tree to non-rooted tree
sub remove_root{
	my $self = shift;
	my @leaf = $self->leaf;
	my $root = $self->root;
	my @child = @{$root->{C}}; ##children 
	
	return if(@leaf == 2 || @child != 2);
	
	my $left_p = $child[0];
	my $right_p = $child[1];
	my $left_num = $self->branch($left_p);
	my $right_num = $self->branch($right_p);
	
	if ($left_num <= $right_num) {
		unshift @{$right_p->{C}},$left_p;
		$left_p->{dist} += $right_p->{dist};
		$self->{_root} = $right_p;
	}else{
		push @{$left_p->{C}},$right_p;
		$right_p->{dist} += $left_p->{dist};
		$self->{_root} = $left_p;
	}
}


##return tree string in nhx text format
sub string
{
	my $self = shift;
	my $root = (@_) ? shift : $self->{_root} ;
	my $type = (@_) ? shift : 'nhx' ; # output as nh or nhx format
	return $self->string_aux($root,$type) . ";\n";
}

##invoked in string()
sub string_aux
{
	my ($self, $root,$type) = @_;
	my $str;
	if ($root->{C}) {
		$str = '(';
		for my $p (@{$root->{C}}) {
			$str .= $self->string_aux($p,$type) . ",\n";
		}
		chop($str); chop($str); # chop the trailing ",\n"
		$str .= "\n)";
		$str .= $root->{N} if ($root->{N}); # node name
		$str .= ":" . $root->{dist} if (defined($root->{dist}) && $root->{dist} >= 0.0); # length
		{ # nhx block
			my $s = '';
			foreach my $p (sort keys %$root) { next if($p eq 'C' || $p eq 'P' || $p eq 'N' || $p eq 'dist'); $s .= ":$p=".$root->{$p}; }
			$str .= "[&&NHX$s]" if ($s && $type eq 'nhx');
		}
	} else { # leaf
		$str = $root->{N};
		$str .= ":" . $root->{dist} if (defined($root->{dist}) && $root->{dist} >= 0.0);
		{ # nhx block
			my $s = '';
			foreach my $p (sort keys %$root) { next if($p eq 'C' || $p eq 'P' || $p eq 'N' || $p eq 'dist'); $s .= ":$p=".$root->{$p}; }
			$str .= "[&&NHX$s]" if ($s && $type eq 'nhx');
		}
	}
	return $str;
}



## parse nhx format into tree structure, 双向链表树，既指向子节点C（数组元素以示顺序），又指向母节点P。
sub parse
{
	my ($self, $str, $type) = @_;
	my ($array, @stack);
	$self->{_error} = 0;
	@{$self->{_node}} = ();
	$array = $self->{_node}; ## $array 是node节点数组的指针
	
	if ($type eq "file") {
		open IN, $str || die "fail to open $str\n";
		$str = "";
		while (<IN>) {
			$str .= $_;
		}
		close IN;
	}

	$_ = $str;
	s/\s//g;
	
	##single leaf tree
	if (!/\(.+?\)/) {
		my %hash;
		$hash{N} = $1 if(/^([^,:;\[\]]+)/);
		push @{$self->{_node}},\%hash;
		$self->{_root} = \%hash;
		$self->{_n_leaf} = 1;
		return;
	}
	
	
	##multi node tree, at least 2 leaf
	s/(\(|((\)?[^,;:\[\]\(\)]+|\))(:[\d.eE\-]+)?(\[&&NHX[^\[\]]*\])?))/&parse_aux($self,$array,\@stack,$1,$3,$4,$5)/eg;
	if (@stack != 1) {
		my $count = @stack;
		warn(qq{[parse] unmatched "(" ($count)});
		$self->{_error} = 1;
		@stack = ();
	}
	if ($self->{_error} == 0) {
		$self->{_root} = shift(@stack);
	} else {
		@{$self->{_node}} = ();
		delete($self->{_root});
	}
	if ($self->{_root}) {
		my $j = 0;
		foreach my $p (@{$self->{_node}}) {
			++$j unless ($p->{C});
		}
		$self->{_n_leaf} = $j;
	}
	return $self->{_root};
}

## invoked in parse(), parse basic unit of nhx format 
sub parse_aux
{
	my ($self, $array, $stack, $str, $name, $dist, $nhx) = @_;
	if ($str eq '(') {
		push(@$stack, $str);
	} elsif ($name) {
		my %hash;
		if ($name =~ /^\)/) {
			my (@s, $t);
			while (($t = pop(@$stack))) {
				last if (ref($t) ne 'HASH');
				push(@s, $t);
			}
			unless (defined($t)) {
				warn('[parse_aux] unmatched ")"');
				$self->{_error} = 1;
				return;
			}
			foreach (@s) {
				#push(@{$hash{C}}, $_);##original code, with right to left order
				unshift(@{$hash{C}}, $_); ##changed by self, with left to right order
				$_->{P} = \%hash;
			}
			$hash{N} = substr($name, 1) if (length($name) > 1);
		} else {
			$hash{N} = $name;
		}
		$hash{dist} = substr($dist, 1) if ($dist);
		$nhx =~ s/:([^=:]+)=([^:=\[\]]+)/$hash{$1}=$2,''/eg if ($nhx);
		push(@$stack, \%hash);
		push(@$array, \%hash);
	}
	return $str;
}


1;

__END__
