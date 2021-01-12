#!/usr/bin/python3

def draw_backbone(scaf, start, end, scale, d, leftmost, topmost, col='black', label=True):
	import svgwrite

	x1 = leftmost
	x2 = x1+(end-start+1)/scale
	y1 = topmost
	y2 = topmost
	d.add(d.line(start = (x1, y1), end = (x2, y2), stroke = col, stroke_width = 1))
	if label: d.add(d.text(scaf, insert = (x1-5, y1-15), font_size = 8, font_family = 'Arial'))

	loc = [x1, y1, start, end]

	return d, loc

