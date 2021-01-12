#!/usr/bin/python3

def read_gff(gff):
	import sys
	import re

	f = open(gff)

	id = ''
	gene_dict = {}
	cds_dict = {}

	for line in f:
		tmp = line.split('\t')
		scaf = tmp[0]
		start = int(tmp[3])
		end = int(tmp[4])
		strand = tmp[6]
		
		if tmp[2] == 'mRNA':
			m = re.search(r'^ID=(\S+?);', tmp[8])
			id = m.group(1)	
			if scaf not in gene_dict: gene_dict[scaf] = []

			m = re.search(r'color=(\S+?);', tmp[8])
			color = ''
			if m == None:
				color = 'red'
			else:
				color = m.group(1)

			gene_dict[scaf].append([id, start, end, strand, color])
		
		elif tmp[2] == 'CDS':
			m = re.search(r'^Parent=(\S+?);', tmp[8])
			if m.group(1) != id:
				sys.exit('error: \nID: %s\n%s' % (id, line))
			
			if id not in cds_dict: cds_dict[id] = []
			
			m = re.search(r'color=(\S+?);', tmp[8])
			color = ''
			if m == None:
				color = 'red'
			else:
				color = m.group(1)
			cds_dict[id].append([scaf, start, end, strand, color])

	return gene_dict, cds_dict

def read_gff_v1(gff):
	import sys
	import re

	f = open(gff)

	id = ''
	gene_dict = {}
	cds_dict = {}

	for line in f:
		tmp = line.split('\t')
		scaf = tmp[0]
		start = int(tmp[3])
		end = int(tmp[4])
		strand = tmp[6]

		if tmp[2] == 'mRNA':
			m = re.search(r'^ID=(\S+?);', tmp[8])
			id = m.group(1)
			#if scaf not in gene_dict: gene_dict[dict] = []
			m = re.search(r'color=(\S+?);', tmp[8])
			color = ''
			if m == None:
				color = 'red'
			else:
				color = m.group(1)
			gene_dict[id] = [scaf, start, end, strand, color]
		elif tmp[2] == 'CDS':
			m = re.search(r'^Parent=(\S+?);', tmp[8])
			if m.group(1) != id:
				sys.exit('error: \nID: %s\n%s' % (id, line))
			if id not in cds_dict: cds_dict[id] = []
			m = re.search(r'color=(\S+?);', tmp[8])
			color = ''
			if m == None:
				color = 'red'
			else:
				color = m.group(1)
			cds_dict[id].append([scaf, start, end, strand, color])
	return gene_dict, cds_dict

def get_path(xloc, yloc, start, end, bg, ed, scale, strand, ort):
	import sys

	path_x = 0
	path_y = 0
	l = (end-start+1)/scale
	h = 0
	l_x = 0
	l_y = 0
	if strand == '+' and ort == '+':
		path_x = xloc + (start-bg+1)/scale
	elif strand == '-' and ort == '+':
		path_x = xloc + (end-bg+1)/scale
	elif strand == '+' and ort == '-':
		path_x = xloc + (ed-start+1)/scale
	elif strand == '-' and ort == '-':
		path_x = xloc + (ed-end+1)/scale
	else:
		sys.exit('Error in strand: %s or ort: %s\n' % (strand, ort))

	path_y = yloc
	if strand == ort:
		h = 0.8*l
		l_x = 0.2*l
		l_y = 6
	else:
		h = -0.8*l
		l_x = -0.2*l
		l_y = 6
	return path_x, path_y, h, l_x, l_y

def get_path_v1(xloc, yloc, start, end, bg, ed, scale, strand, ort, axis):
	path_x = 0
	path_y = 0
	l = (end-start+1)/scale
	h = 0
	l_x = 0
	l_y = 0
	if axis == 'x':
		start_point = xloc
		path_y = yloc
	elif axis == 'y':
		start_point = yloc
		path_x = xloc
	if strand == '+' and ort == '+':
		s = start_point + (start-bg+1)/scale
	elif strand == '-' and ort == '+':
		s = start_point + (end-bg+1)/scale
	elif strand == '+' and ort == '-':
		s = start_point + (ed-start+1)/scale
	elif strand == '-' and ort == '-':
		s = start_point + (ed-end+1)/scale
	else:
		sys.exit('Error in strand: %s or ort: %s\n' % (strand, ort))

	if strand == ort:
		h = 0.8*l
		l_x = 0.2*l
		l_y = 6
	else:
		h = -0.8*l
		l_x = -0.2*l
		l_y = 6
	if axis == 'x':
		return s, path_y, h, l_x, l_y
	elif axis == 'y':
		return path_x, s, h, l_y, l_x

def draw_gene(gene_list, d, scale, leftmost, topmost, ort='+', bg='NA', ed='NA', arrow=True, name=True):
	import svgwrite
	import sys

	if ort != '+' and ort != '-': sys.exit('error in ort argument: %s\nshould be "+" or "-"' % (ort))


	xloc = leftmost
	yloc = topmost
	
	if bg == 'NA':
		bg = sorted(gene_list, key = lambda x: x[1])[0][1]
		ed = sorted(gene_list, key = lambda x: x[2])[-1][2]
	
	# draw backbone and scaf ID
	#d.add(d.line(start = (xloc-20, yloc), end = (xloc+l+20, yloc), stroke = 'black', stroke_width = 1))
	#d.add(d.text(scaf, insert = (xloc-5, yloc-15), font_size = 8, fill = 'black', font_family = 'Arial'))

	for info in sorted(gene_list, key = lambda x: x[1]):
		id, start, end, strand, color = info[:]
		# draw gene and gene ID
		if name: d.add(d.text(id, insert = (xloc-5, yloc), font_size = 8, fill = 'black', font_family = 'Arial'))
		if arrow:
			## NEED TO FIX ORT AND STRAND SITUATION
			path_x, path_y, h, l_x, l_y = get_path(xloc, yloc, start, end, bg, ed, scale, strand, ort)
			d.add(d.path('M%f %f v -3 h %f v -3 l %f %f M%f %f v 3 h %f v 3 l %f -%f' % (path_x, path_y, h, l_x, l_y, path_x, path_y, h, l_x, l_y), fill = color, stroke = 'black', stroke_width = 0.5))
		else:
			l = (end-start+1)/scale
			if ort=='+':
				x = (start-bg+1)/scale+xloc
			else:
				x = (ed-end+1)/scale+xloc
			d.add(d.rect(insert=(x, yloc-5), size=(l, 10), fill = color, stroke = 'black', stroke_width = 0.5))
		
	return d

def draw_gene_v1(gene_info, id, d, scale, leftmost, topmost, ort='+', bg='NA', ed='NA', arrow=True, name=True):
	import svgwrite
	import sys

	if ort != '+' and ort != '-': sys.exit('error in ort argument: %s\nshould be "+" or "-"' % (ort))

	xloc = leftmost
	yloc = topmost

	if bg == 'NA':
		bg = gene_info[1]
		ed = gene_info[2]

	scaf, start, end, strand, color = gene_info[:]
	
	x = 0
	
	if arrow:
		path_x, path_y, h, l_x, l_y = get_path(xloc, yloc, start, end, bg, ed, scale, strand, ort)
		d.add(d.path('M%f %f v -3 h %f v -3 l %f %f M%f %f v 3 h %f v 3 l %f -%f' % (path_x, path_y, h, l_x, l_y, path_x, path_y, h, l_x, l_y), fill = color, stroke = 'black', stroke_width = 0.5))
		if name:
			if strand == '+':
				d.add(d.text(id, insert = (path_x-5, path_y-8), font_size = 8, fill = 'black', font_family = 'Arial'))
			else:
				d.add(d.text(id, insert = (path_x+h+l_x-5, path_y-8), font_size = 8, fill = 'black', font_family = 'Arial'))
	else:
		if ort == '+':
			x = start-bg+1
		elif ort == '-':
			x = ed-end+1
		l = (end-start+1)/scale
		d.add(d.rect(insert=(xloc+x/scale, yloc-5), size=(l, 10), fill = color, stroke = 'black', stroke_width = 0.5))
		if name: d.add(d.text(id, insert = (x-5, yloc-5-8), font_size = 8, fill = 'black', font_family = 'Arial'))
	return d

def draw_gene_v2(gene_info, id, d, scale, leftmost, topmost, ort='+', bg='NA', ed='NA', arrow=True, name=True, axis='x'):
	import svgwrite
	import sys

	if ort != '+' and ort != '-': sys.exit('error in ort argument: %s\nshould be "+" or "-"' % (ort))

	xloc = leftmost
	yloc = topmost

	if bg == 'NA':
		bg = gene_info[1]
		ed = gene_info[2]

	scaf, start, end, strand, color = gene_info[:]

	x = 0

	if arrow:
		path_x, path_y, h, l_x, l_y = get_path_v1(xloc, yloc, start, end, bg, ed, scale, strand, ort, axis=axis)
		if axis == 'x':
			d.add(d.path('M%f %f v -3 h %f v -3 l %f %f M%f %f v 3 h %f v 3 l %f %f' % (path_x, path_y, h, l_x, l_y, path_x, path_y, h, l_x, -l_y), fill = color, stroke = 'black', stroke_width = 0.5))
		elif axis == 'y':
			d.add(d.path('M%f %f h -3 v %f h -3 l %f %f M%f %f h 3 v %f h 3 l %f %f' % (path_x, path_y, h, l_x, l_y, path_x, path_y, h, -l_x, l_y), fill = color, stroke = 'black', stroke_width = 0.5))
		if name:
			if strand == '+':
				if axis == 'x':
					d.add(d.text(id, insert = (path_x-5, path_y-8), font_size = 8, fill = 'black', font_family = 'Arial'))
				elif axis == 'y':
					d.add(d.text(id, insert = (path_x-5, path_y-8), font_size = 8, fill = 'black', font_family = 'Arial'))
			else:
				if axis == 'x':
					d.add(d.text(id, insert = (path_x+h+l_x-5, path_y-8), font_size = 8, fill = 'black', font_family = 'Arial'))
				elif axis == 'y':
					d.add(d.text(id, insert = (path_x-8, path_y+h+l_x), font_size = 8, fill = 'black', font_family = 'Arial'))
	else:
		if ort == '+':
			x = start-bg+1
		elif ort == '-':
			x = ed-end+1
		l = (end-start+1)/scale
		if axis == 'x':
			d.add(d.rect(insert=(xloc+x/scale, yloc-5), size=(l, 10), fill = color, stroke = 'black', stroke_width = 0.5))
		elif axis == 'y':
			d.add(d.rect(insert=(xloc-5, yloc+x/scale), size=(10, l), fill = color, stroke = 'black', stroke_width = 0.5))
		if name:
			if axis == 'x':
				d.add(d.text(id, insert = (x-5, yloc-5-8), font_size = 8, fill = 'black', font_family = 'Arial'))
			elif axis == 'y':
				d.add(d.text(id, insert = (x-5, yloc-5-8), font_size = 8, fill = 'black', font_family = 'Arial'))
	return d

def draw_gene_model(cds_list, id, d, scale, leftmost, topmost, ort='+', bg='NA', ed='NA', arrow=True, name=True):
	import svgwrite
	import sys

	if ort != '+' and ort != '-': sys.exit('error in ort argument: %s\nshould be "+" or "-"' % (ort))

	xloc = leftmost
	yloc = topmost

	if bg == 'NA':
		sort_info = sorted(cds_list, key = lambda x: x[1])
		bg = sort_info[0][1]
		ed = sort_info[-1][2]

	l = (ed-bg+1)/scale
	scaf = cds_list[0][0]
		
	#if name==1: d.add(d.text(id, (xloc-5, yloc-5), font_size = 8, fill = 'black', font_family = 'Arial'))
	
	count = 0
	cds_list = sorted(cds_list, key = lambda x: x[1])
	for info in cds_list:
		count += 1
		scaf, start, end, strand, color = info[:]
		l = (end-start+1)/scale
	
		x = (start-bg+1)/scale+xloc
		if ort == '+':
			x = (start-bg+1)/scale+xloc
		elif ort == '-':
			x = (ed-end+1)/scale+xloc
		y = yloc-5

		# draw CDS
		## draw the first CDS in mRNA
		tri_y1, tri_y2, tri_y3 = yloc, yloc+10, yloc-10
		tri_x1, tri_x2, tri_x3 = 0, 0, 0

		if strand == ort:
			tri_x1 = x+l
			tri_x2 = x
			tri_x3 = x
		else:
			tri_x1 = x
			tri_x2 = x+l
			tri_x3 = x+l

		if name and count == 1: d.add(d.text(id, (x-5, yloc-8), font_size = 8, fill = 'black', font_family = 'Arial'))

		if strand == '+' and count == len(cds_list):
				d.add(d.polygon(points = ((tri_x1, tri_y1), (tri_x2, tri_y2), (tri_x3, tri_y3)), fill = color, stroke = 'black', stroke_width = 0.5))
				continue
		if strand == '-' and count == 1:
				d.add(d.polygon(points = ((tri_x1, tri_y1), (tri_x2, tri_y2), (tri_x3, tri_y3)), fill = color, stroke = 'black', stroke_width = 0.5))
				continue
		## draw the remaining CDS
		d.add(d.rect(insert = (x, y), size = (l, 10), fill = color, stroke = 'black', stroke_width = 0.5))

	return d

def main():
	import sys
	import svgwrite

	if len(sys.argv) != 4:
		sys.exit('python3 %s <gff> <gene|exon> <scale>' % (sys.argv[0]))
	elif sys.argv[2] != 'gene' and sys.argv[2] != 'exon':
		sys.exit('python3 %s <gff> <gene|exon> <scale>\n## please specify drawing type' % (sys.argv[0]))

	gff = sys.argv[1]
	typ = sys.argv[2]
	scale = int(sys.argv[3])

	gene_dict, cds_dict = read_gff(gff)
	d = svgwrite.Drawing('tmp.svg')

	leftmost = 25
	topmost = 25

	if typ == 'gene':
		for scaf in gene_dict:
			d = draw_gene(gene_dict[scaf], d, scale, leftmost, topmost)
			topmost += 50
	elif typ == 'exon':
		for id in cds_dict:
			d = draw_gene_exons(cds_dict[id], id, d, scale, leftmost, topmost)
			topmost += 50

	d.save()

if __name__ == '__main__':
	main()

