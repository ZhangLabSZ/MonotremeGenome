## draw SVG tree figure with nh or nhx text format
## Creat on: 2006-3-28
package Tree::nhx_svg;
use strict;
use SVG;
use SVG::Font;
use Tree::nhx;
use vars qw(@ISA);
@ISA = qw(Tree::nhx);


## creat a new obejct, and set the parameters
sub new
{	
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;
	my $self = Tree::nhx->new(
		_node=>undef,				_root=>undef,
		_n_leaf=>undef,				_error=>undef,
							
		tree_dist=>0,				tree_width=>0,			
		width=>640,					height=>480, 
		left_margin=>60,			right_margin=>60,
		top_margin=>30,				bottom_margin=>10,
		skip=>40,					is_real=>1,
		half_box=>3,				c_node=>"#0000FF",
		line_width=>1,				c_line=>"#00FF00",
		font=>'ArialNarrow',			fsize=>12,
		fsize2=>10,
		c_bg=>"#FFFFFF",			c_frame=>"#FF00CC", 
		c_inter=>"#FF6600",			c_exter=>"#000000",
		c_status=>"#FF0000",		c_W=>"#FF00CC",
		c_B=>"#330099",				show_B=>0,
		show_inter=>0,				show_exter=>1,
		show_ruler=>0,				show_W=>0,
		show_frame=>0,				view_cut=>0,
		exter_include=>0,			_svg=>'',
		show_legend=>0,				legend_height=>80,
		show_header=>0,				header_height=>50,
		header_content=>'',
		@_ );
	
	bless($self, $class);
	return $self;
}

##text width and text height caculation
#$swdith = textWidth($font_family,$font_size,$str);
#$sheight = textHeight($font_size);

##caculate logical X,Y(大写) of each node
##整棵树的纵向距离设为 1 ,最上节点Y为0，每个向下叶节点逐渐加1，最后都除以(叶节点个数-1)。
##无论真枝长还是均枝长，树横向总距离都是 1；
sub cal_XY
{
	my $self = shift;
	my ($i, $j, $scale);
	my $is_real = $self->{is_real};
	my $array = $self->{_node};
	
	##循环 数组@{$self->{_node}}一次, 即按左右中顺序遍历整个树一遍。
	
	if ($self->{_n_leaf} == 1) {
		foreach my $p (@$array) {
			$p->{X} = 0;
			$p->{Y} = 0;
		}
		return;
	}

	#caculate Y
	$j = 0;
	$scale = $self->{_n_leaf} - 1; #$scale shoule plus 1，change by Fanwei
	foreach my $p (@$array) {
		$p->{Y} = ($p->{C})? ($p->{C}[0]->{Y} + $p->{C}[@{$p->{C}}-1]->{Y}) / 2.0 : ($j++) / $scale;
	}
	
	my $add_dist;
	foreach my $p (@$array) {
		$add_dist += $p->{dist};
	}
	$is_real = 0 if(!$add_dist);

	#calculate X
	if ($is_real) {		
		##根节点如果有dist则使用，否则根节点X设置为0, 此处$scale为整棵树X方向上最大的逻辑长度 
		$scale = $$self{_root}{X} = (defined($$self{_root}{dist}) && $$self{_root}{dist} > 0.0)? $$self{_root}{dist} : 0.0;
		for (my $i = @$array - 2; $i >= 0; --$i) {
			my $p = $array->[$i];
			$p->{X} = $p->{P}->{X} + (($p->{dist} >= 0.0)? $p->{dist} : 0.0);
			$scale = $p->{X} if ($p->{X} > $scale);
		}
	} else {
		##如不使用真枝长， 根节点处X设置为 0， 然后逐级 加 1
		$scale = $$self{_root}{X} = 0.0; ##changed by FanWei
		for (my $i = @$array - 2; $i >= 0; --$i) {
			my $p = $array->[$i];
			$p->{X} = $p->{P}->{X} + 1.0;
			$scale = $p->{X} if ($p->{X} > $scale);
		}
		
		##使所有叶节点X相同，显示在同一条纵线上。
		foreach my $p (@$array) {
			$p->{X} = $scale unless ($p->{C});
		}
	}
	
	##无论真枝长还是均枝长，都是最大X变为1
	foreach my $p (@$array) {	
		$p->{X} /= $scale;
	}

	##最短枝0修正
	foreach my $p (@$array) {	
		if (exists $p->{P} && $p->{X} - $p->{P}->{X} < 0.02 ) {
			$p->{X} += 0.02;
		}
	}
	$self->{tree_dist} = $scale;
}


## caculate 像素坐标 x， y（小写）
sub cal_xy{
	my $self = shift;
	$self->cal_XY;

	## get max length of name space 
	my $max = 0; # the max length of leaf names
	my $array = $self->{_node};
	foreach my $p (@$array) {
		my $tw = textWidth($self->{font},$self->{fsize},$p->{N});
		$max = $tw if (!$p->{C} && $tw > $max);
	}

	## 当skip非零时，图像高度height由叶节点个数决定，否则为指定的height值，而width则只能指定。
	if ($self->{skip}){
		$self->{height} = $self->{top_margin} + $self->{bottom_margin} + $self->{skip} * ($self->{_n_leaf}-1);
		$self->{height} += $self->{skip} if($self->{show_ruler});
		$self->{height} += $self->{legend_height} if($self->{show_legend} && $self->{legend_height} > 0);
		$self->{height} += $self->{header_height} if($self->{show_header} && $self->{header_height} > 0);
		
	}
	
	
	## 树的像素宽度，像素高度，树原点与图像原点之间的x差，树原点与图像原点之间的y差
	my ($real_x, $real_y, $shift_x, $shift_y);
	
	$real_x = $self->{width} - $self->{left_margin} - $self->{right_margin} ;
	$real_x -=  $max if($self->{exter_include});
	$real_y = $self->{height} - $self->{top_margin} - $self->{bottom_margin};
	
	$real_y -= $self->{skip} if($self->{show_ruler});
	$real_y -= $self->{legend_height} if($self->{show_legend});
	$real_y -= $self->{header_height} if($self->{show_header});
	$shift_x = $self->{left_margin};  
	$shift_y = $self->{top_margin}; 

	my $half = $self->{half_box}; 
	foreach my $p (@$array) {
		
		## 逻辑坐标X和Y的最大值都是1，此处计算实际像素坐标x和y，加0.5四舍五入，int只返回整数部分
		$p->{x} = int($p->{X} * $real_x + $shift_x + 0.5);
		$p->{y} = int($p->{Y} * $real_y + $shift_y + 0.5);
		
		## 计算叶节点名字区域坐标，used for web information mapping
		if (!$p->{C}) {
			$p->{name_area} = [ int($p->{x}+$self->{half_box}+3),
				int($p->{y}-textHeight($self->{fsize})/2),
				int($p->{x}+$self->{half_box}+3+textWidth($self->{font},$self->{fsize},$p->{N})),
				int($p->{y}+textHeight($self->{fsize})/2) ];
		}
		
	}
	$self->{tree_width} = $real_x;
}


## draw ruler for tree branches and exon blocks
sub plot_ruler{
	my ($self,$Y,$X_start,$X_end,$len,$type,$pos) = @_ ;
	my $svg = $self->{_svg};
	my $scale_size = 6;
	
	## draw the main axis
	$svg->line('x1',$X_start,'y1',$Y,'x2',$X_end,'y2',$Y,'stroke','#000000','stroke-width',1);		
	return if($len == 0);
	#$svg->text('x',$X_start,'y',$Y-20,'-cdata',$type,"font-family",$self->{font},"font-size",$self->{fsize},"fill",'#0000    00');

	##draw ruler mark text at the specified postion(left or right of the ruler)
	if ($pos eq '' || $pos eq "left") {
		$svg->text('x',$X_start,'y',$Y-10,'-cdata',$type,"font-family",$self->{font},"font-size",$self->{fsize2},"fill",'#000000');
	}
	if ($pos eq "right") {
		$svg->text('x',$X_end + 4,'y',$Y,'-cdata',$type,"font-family",$self->{font},"font-size",$self->{fsize2},"fill",'#000000');
	}
	
	
	my ($divid,$str,$str1,$str2,$unit);
	$divid = 5;
	$str = $len / $divid;
	$str = sprintf("%e",$str);
	if ($str=~/([\d\.]+)e([+-\d]+)/) {
		$str1 = $1;
		$str2 = $2;
	}
	$str1 = int ( $str1 + 0.5 );
	$unit = $str1 * 10 ** $str2;
	
	## draw small scale lines
	for (my $i=0; $i<=$len; $i+=$unit/5) {
		
		my $X = $X_start + $i / $len * ($X_end - $X_start);
		$svg->line('x1',$X,'y1',$Y - $scale_size/2,'x2',$X,'y2',$Y,'stroke','#000000','stroke-width',1);
	}
	
	## draw big scales lines and texts 
	for (my $i=0; $i<=$len; $i+=$unit) {
		my $X = $X_start + $i / $len * ($X_end - $X_start);
		$svg->line('x1',$X,'y1',$Y - $scale_size,'x2',$X,'y2',$Y,'stroke','#000000','stroke-width',1);
		$svg->text('x',$X - textWidth($self->{font},$self->{fsize},$i) / 2,'y',$Y+textHeight($self->{fsize})+4,'fill','#000000','-cdata',$i,'font-size',$self->{fsize}, 'font-family',$self->{font});
	}

}

## draw status mark
sub draw_status{
	my ($self,$x,$y,$r) = @_ ;
	my $CIR = 2 * 3.1415926;
	my $svg = $self->{_svg};
	$svg->polygon('points',
	[
	$x,$y-$r,
	$x + $r * cos(2*$CIR/5-$CIR/4), $y + $r * sin(2*$CIR/5-$CIR/4),
	$x - $r * cos($CIR/4-$CIR/5), $y - $r * sin($CIR/4-$CIR/5),
	$x + $r * cos($CIR/4-$CIR/5), $y - $r * sin($CIR/4-$CIR/5),
	$x - $r * cos(2*$CIR/5-$CIR/4), $y + $r * sin(2*$CIR/5-$CIR/4)
	],
	'fill','red');
	
}


## draw legend
sub draw_tree_legend{
	my $self = shift;
	my $svg = $self->{_svg};
	my $legend_y = $self->{height} - $self->{bottom_margin} - $self->{legend_height} + 30;
	my $horizontal_shift = 105;
	my $vertical_shift = 20;
	
	my ($x,$y) = ($self->{left_margin},$legend_y);
	$svg->rect('x',$x, 'y',$y,'width',$self->{half_box}*2,'height',$self->{half_box}*2,'fill',$self->{c_node});
	$svg->text('x',$x+30,'y',$y+$self->{half_box}*2,'-cdata','Node', 'font-size',$self->{fsize}, 'font-family',$self->{font});
	
	$y += $vertical_shift;
	$svg->line('x1',$x,'y1',$y,'x2',$x+20,'y2',$y,'stroke',$self->{c_line},'stroke-width',$self->{line_width});
	$svg->text('x',$x+30,'y',$y+$self->{half_box}*2,'-cdata','Branch','font-size',$self->{fsize}, 'font-family',$self->{font});
	
	$x += $horizontal_shift;
	$y -= $vertical_shift;
	$svg->text('x',$x,'y',$y+$self->{half_box}*2,'-cdata','float','font-size',$self->{fsize}, 'font-family',$self->{font},"fill",$self->{c_W});
	$svg->text('x',$x+40,'y',$y+$self->{half_box}*2,'-cdata','Ka/Ks ratio','font-size',$self->{fsize}, 'font-family',$self->{font});

	
	$y += $vertical_shift;
	$svg->text('x',$x,'y',$y+$self->{half_box}*2,'-cdata','int','font-size',$self->{fsize}, 'font-family',$self->{font},"fill",$self->{c_B});
	$svg->text('x',$x+40,'y',$y+$self->{half_box}*2,'-cdata','Bootstrap','font-size',$self->{fsize}, 'font-family',$self->{font});

	$x += $horizontal_shift+5;
	$y -= $vertical_shift;
	$svg->text('x',$x,'y',$y+$self->{half_box}*2,'-cdata','text','font-size',$self->{fsize}, 'font-family',$self->{font},"fill",$self->{c_exter});
	$svg->text('x',$x+40,'y',$y+$self->{half_box}*2,'-cdata','Paralog ID','font-size',$self->{fsize}, 'font-family',$self->{font});

	
	$y += $vertical_shift;
	$svg->text('x',$x+40,'y',$y+$self->{half_box}*2,'-cdata','Best hit','font-size',$self->{fsize}, 'font-family',$self->{font});
	my $CIR = 2 * 3.1415926;
	my $r = 7;
	$x += 7;
	$y += 3;
	my $svg = $self->{_svg};
	$svg->polygon('points',
	[
	$x,$y-$r,
	$x + $r * cos(2*$CIR/5-$CIR/4), $y + $r * sin(2*$CIR/5-$CIR/4),
	$x - $r * cos($CIR/4-$CIR/5), $y - $r * sin($CIR/4-$CIR/5),
	$x + $r * cos($CIR/4-$CIR/5), $y - $r * sin($CIR/4-$CIR/5),
	$x - $r * cos(2*$CIR/5-$CIR/4), $y + $r * sin(2*$CIR/5-$CIR/4)
	],
	'fill','red');

}



sub plot_core{
	my $self = shift;
	$self->cal_xy;
	my $array = $self->{_node};
	
	##my ($view_width,$view_height) = ($self->{view_cut}) ? ($self->{width},$self->{height}) : (10000,10000);
	##my $figure_height = ($self->{_n_leaf} - 1) * $self->{skip} + $self->{top_margin} + $self->{bottom_margin};

	my $svg = SVG->new('width',$self->{width}+100,'height',$self->{height}+20);
	$self->{_svg} = $svg;
	
	## set backgroud color, and draw a frame for the whole figure
	$svg->rect('x',0, 'y',0,'width',$self->{width}+100,'height',$self->{height}+20,'fill',$self->{c_bg});
	$svg->rect('x',0, 'y',0,'width',$self->{width}-1,'height',$self->{height}-1,'stroke',$self->{c_frame},'fill','none') if($self->{show_frame});

	
	
	# draw external node names
	foreach my $p (@$array) {
		if($self->{show_exter} && !$p->{C}
		&& $p->{N}) {
			#my $color = (defined $p->{status} && $p->{status} == 1) ? $self->{c_status} : $self->{c_exter} ;
			my $outname = (defined $p->{replace}) ? $p->{replace} : $p->{N};
			
			$svg->text('x',$p->{x}+$self->{half_box}+4,'y',$p->{y}+textHeight($self->{fsize})/2,'fill',$self->{c_exter},'-cdata',$outname,'font-size',$self->{fsize}, 'font-family',$self->{font});
		}
	}
	
	# draw internal node names
	foreach my $p (@$array) {
		if ($self->{show_inter} && $p->{C} && $p->{N}){
			$svg->text('x',$p->{x}-textWidth($self->{font},$self->{fsize},$p->{N})-$self->{half_box}-2,'y',$p->{y}-2,'fill',$self->{c_inter},'-cdata',$p->{N},'font-size',$self->{fsize}, 'font-family',$self->{font});
		}	
	}
	
	# draw horizontal lines, 如果根节点处为二叉树,则画一短线以示为有根的树
	if( $self->root->{C} && @{$$self{_root}{C}} == 2 ){
		$svg->line('x1',$self->{left_margin}/2,'y1',$$self{_root}{y},'x2',$$self{_root}{x},'y2',$$self{_root}{y},'stroke',$self->{c_line},'stroke-width',$self->{line_width});
	}
	foreach my $p (@$array) {
		if ($p != $self->{_root}){
			$svg->line('x1',$p->{x},'y1',$p->{y},'x2',$p->{P}->{x},'y2',$p->{y},'stroke',$self->{c_line},'stroke-width',$self->{line_width});		
		}
	}
	
	# draw vertical lines
	foreach my $p (@$array) {
		if ($p->{C}){
			$svg->line('x1',$p->{x},'y1',$p->{C}[0]->{y},'x2',$p->{x},'y2',$p->{C}[@{$p->{C}}-1]->{y},'stroke',$self->{c_line},'stroke-width',$self->{line_width});		
		}
	}
	
	# draw rectangle nodes 
	#foreach my $p (@$array) {
	#	if($p->{status} != 1){
			##print "##$p->{D}\n";
	#		my $color = (exists $p->{D} && $p->{D} eq "Y") ? "red" : $self->{c_node};
	#		$svg->rect('x',$p->{x}-$self->{half_box}, 'y',$p->{y}-$self->{half_box},'width',$self->{half_box}*2,'height',$self->{half_box}*2,'fill',$color);
	#	}else{
	#		$self->draw_status($p->{x}-$self->{half_box},$p->{y}-$self->{half_box}+2,7);
	#	}
#	}

	
	
	## draw ruler
	my $ruler_y = $self->{height} - $self->{bottom_margin};
	$ruler_y -= $self->{legend_height} if($self->{show_legend});
	$self->plot_ruler( $ruler_y,$self->{left_margin}, $self->{left_margin} + $self->{tree_width}, $self->{tree_dist}, "Divergence, substitutions/site" ) if($self->{show_ruler} && $self->{tree_width} );
	
	## draw legend 
	$self->draw_tree_legend() if($self->{show_legend});
	
	## draw header
	$svg->text('x',$self->{left_margin},'y',$self->{header_height}-5,'fill','black','-cdata',$self->{header_content},'font-size',$self->{fsize}*4/3, 'font-family',"ArialNarrow-Bold") if($self->{show_header});
	
	## draw tag of Ka/Ks
	foreach my $p (@$array) {
		if($self->{show_W} && defined $p->{W}) {
			my $W_str = ($p->{W}=~/\d/) ? sprintf("%.2f",$p->{W}) : $p->{W};
			#my $color = ($p->{W} > 1) ? $self->{c_W} : "black";
			my $color = $self->{c_W};
			my $detail = "Dn=$p->{Dn};\\nDs=$p->{Ds};\\nDn/Ds=$p->{W}";
			my $sw = textWidth($self->{font},$self->{fsize2},$W_str);
			my $x = ($p->{x} - $self->{half_box} - $p->{P}->{x}  >= $sw*1.5) ? ($p->{P}->{x} + $p->{x} - $self->{half_box} - $sw)/2 : ($p->{x} - $self->{half_box} - $sw - 5);
			$svg->text('x',$x,'y',$p->{y}-3,'fill',$color,'-cdata',$W_str,'font-size',$self->{fsize2}, 'font-family',$self->{font}, 'onclick',"alert('$detail')");
			@{$p->{kaks_area}} = ( int($x), int($p->{y}+10 - textHeight($self->{fsize2})), 
				int($x+textWidth($self->{font},$self->{fsize2},$W_str)) , int($p->{y}-4) );	
		}
	}
	
	## draw tag of B (B)
	foreach my $p (@$array) {
		next if($p eq $self->root && $p->{B} == 0);
		if($self->{show_B}  && defined $p->{B}) {
			my $str = sprintf("%d",$p->{B});
			my $sw = textWidth($self->{font},$self->{fsize2},$str);
			my $x = ($p->{x} - $self->{half_box} - $p->{P}->{x}  >= $sw) ? ($p->{P}->{x} + $p->{x} - $self->{half_box} - $sw)/2 : ($p->{x} - $self->{half_box} - $sw ) ;
			$x = $p->{x} - $self->{half_box} - $sw - 5 if($p eq $self->root);
			$svg->text('x',$x,'y',$p->{y}+textHeight($self->{fsize2})-15,'fill',$self->{c_B},'-cdata',$str,'font-size',$self->{fsize2}, 'font-family',$self->{font});
		}
	}
}




## 绘制进化树树的图
sub plot{
	my $self = shift;
	$self->plot_core();	
	my $out = $self->{_svg}->xmlify();
#	$out =~ s/<!DOCTYPE.+?>//s;
#	$out =~ s/\s+xmlns=.+?>/>/s;
#	$out =~ s/<!--.+?-->//s;
	return $out;

}

1;

__END__

