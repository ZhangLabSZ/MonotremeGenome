#!/usr/bin/python3
from draw_backbone import draw_backbone

def read_aln(file):
	import sys

	aln_dict = {}

	f = open(file)
	for line in f:
		line = line.rstrip()

		tmp = line.split('\t')
		scaf1, strand1, bg1, ed1, scaf2, strand2, bg2, ed2 = tmp[0:8]
		if bg1 == '-' or ed1 == '-' or bg2 == '-' or ed2 == '-': continue
		bg1 = int(bg1)
		ed1 = int(ed1)
		bg2 = int(bg2)
		ed2 = int(ed2)
		
		if strand1 != strand2:
			bg2, ed2 = ed2, bg2
		if len(tmp) >= 9:
			color = tmp[8]
		else:
			color = '#969696'

		key1 = '%s#%s' % (scaf1, scaf2)
		if key1 not in aln_dict: aln_dict[key1] = []
		aln_dict[key1].append([scaf1, strand1, bg1, ed1, scaf2, strand2, bg2, ed2, color])
		
		key2 = '%s#%s' % (scaf2, scaf1)
		if key2 not in aln_dict: aln_dict[key2] = []
		aln_dict[key2].append([scaf2, strand2, bg2, ed2, scaf1, strand1, bg1, ed1, color])

	return aln_dict

def get_aln_range(aln_list):
	rang1 = ['', -1, -1]
	rang2 = ['', -1, -1]

	import sys
	for info in aln_list:
		scaf1, strand1, bg1, ed1, scaf2, strand2, bg2, ed2, color = info
		#sys.exit(type(rang2[1]))

		rang1[0] = scaf1
		if rang1[1] == -1:
			rang1[1] = bg1
			rang1[2] = ed1
		else:
			if rang1[1] > bg1: rang1[1] = bg1
			if rang1[2] < ed1: rang1[2] = ed1
		
		rang2[0] = scaf2
		if rang2[1] == -1:
			rang2[1] = bg2
			rang2[2] = ed2
		else:
			if rang2[1] > bg2: rang2[1] = bg2
			if rang2[2] < ed2: rang2[2] = ed2

	return rang1, rang2

def draw_aln(aln_list, d, scale, leftmost1, topmost1, leftmost2, topmost2, ort1='+', ort2='+', bg1='NA', ed1='NA', bg2='NA', ed2='NA', path=1):
	import svgwrite
	import sys

	rang1, rang2 = get_aln_range(aln_list)
	
	# 1st backbone
	xloc1 = leftmost1
	yloc1 = topmost1
	scaf1 = rang1[0]

	if bg1 == 'NA':
		bg1, ed1 = rang1[1:]

	l = (ed1-bg1+1)/scale
	#d.add(d.line(start = (xloc1-20, yloc1), end = (xloc1+l+20, yloc1), stroke = 'black', stroke_width = 1))
	#d.add(d.text(scaf1, insert = (xloc1-5, yloc1-15), font_size = 8, font_family = 'Arial'))

	# 2nd backbone
	xloc2 = leftmost2
	yloc2 = topmost2
	scaf2 = rang2[0]
	if bg2 == 'NA':
		bg2, ed2 = rang2[1:]
	
	l = (ed2-bg2+1)/scale
	#d.add(d.line(start = (xloc2-20, yloc2), end = (xloc2+l+20, yloc2), stroke = 'black', stroke_width = 1))
	#d.add(d.text(scaf2, insert = (xloc2-5, yloc2-15), font_size = 8, font_family = 'Arial'))

	# draw aln
	for info in aln_list:
		scaf1, strand1, start1, end1, scaf2, strand2, start2, end2, color = info
		
		if end1 < bg1 or start1 > ed1 or end2 < bg2 or start2 > ed2:
			continue
		
		if ort1 == '+':
			x1 = xloc1+(start1-bg1+1)/scale
			x2 = xloc1+(end1-bg1+1)/scale
		else:
			x1 = xloc1+(ed1-start1+1)/scale
			x2 = xloc1+(ed1-end1+1)/scale
		y1 = yloc1
		y2 = yloc1

		if ort2 == '+':
			x3 = xloc2+(end2-bg2+1)/scale
			x4 = xloc2+(start2-bg2+1)/scale
		else:
			x3 = xloc2+(ed2-end2+1)/scale
			x4 = xloc2+(ed2-start2+1)/scale
		y3 = yloc2
		y4 = yloc2
		
		if path:
			mid = (y1+y3)/2
			d.add(d.path('M %i %i H %i C %i %i, %i %i, %i %i H %i C %i %i, %i %i, %i %i Z' % (x1, y1, x2, x2, mid, x3, mid, x3, y3, x4, x4, mid, x1, mid, x1, y1), fill = color, stroke = 'none', stroke_width = 0, opacity = 0.3))
		else:
			d.add(d.polygon(points = ((x1, y1), (x2, y2), (x3, y3), (x4, y4)), fill = color, stroke = 'none', stroke_width = 0, opacity = 0.3))

	return d

def main():
	import sys
	import svgwrite

	if len(sys.argv) != 3:
		sys.exit('python3 %s <aln> <scale>' % (sys.argv[0]))
	
	file = sys.argv[1]
	scale = int(sys.argv[2])
	aln_dict = read_aln(file)

	leftmost1 = 25
	topmost1 = 25
	leftmost2 = 25
	topmost2 = 25+50

	d = svgwrite.Drawing('tmp1.svg')
	for key in aln_dict:
		d = draw_aln(aln_dict[key], d, scale, leftmost1, topmost1, leftmost2, topmost2)
	d.save()

if __name__ == '__main__':
	main()

