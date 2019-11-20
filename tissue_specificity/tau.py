#!/usr/bin/python3

def main():
	import sys
	if len(sys.argv) != 2:
		sys.exit('python3 %s <rpkm.tab>' % (sys.argv[0]))

	tabFile = sys.argv[1]

	import csv
	f = open(tabFile)
	reader = csv.reader(f, delimiter = '\t')
	h = next(reader, None)
	hout = '\t'.join(h + ['TAU', 'TISSUE', 'max_exp', 'foldchange'])
	print(hout)

	import statistics
	for row in reader:
		dic = {}

		tau = ''
		tissue = ''
		max_expr = max([float(i) for i in row[1:]])
		foldchange = ''

		if max_expr == 0.0:
			tau = '0.000000'
			tissue = 'NA'
			foldchange = 'NA'
		else:
			x_hat = []
			tau = 0.0
			for i in range(1, len(row)):
				dic[h[i]] = float(row[i])/float(max_expr)
				tau += 1-dic[h[i]]
			tau = '%.6f' % (tau/(len(row)-1-1))
			order = sorted(dic, key=lambda x: dic[x], reverse=True)

			for i in range(len(order)):
				tissue = order[i]
				if dic[order[i+1]] == 0:
					foldchange = 'NA'
				else:
					foldchange = '%.6f' % (dic[order[i]]/dic[order[i+1]])
				break
				foldchange = 'NA'
		max_expr = '%.6f' % (max_expr)

		out = '\t'.join(row + [tau, tissue, max_expr, foldchange])
		print(out)

if __name__ == '__main__':
	main()

