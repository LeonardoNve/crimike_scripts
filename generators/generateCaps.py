import itertools
import sys

def cc(s):
	return (''.join(t) for t in itertools.product(*zip(s.lower(), s.upper())))

li = cc(sys.argv[1])

if len(sys.argv) < 3 or sys.argv[2] == 'p':
	for el in li:
		print el
else:
	with open(sys.argv[1], 'w') as f:
		for el in li:
			f.write(el + "\n")
