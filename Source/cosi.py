files = [
	'ARTAuth.m',
	'ARTChannels.m',
	'ARTJsonLikeEncoder.m',
	'ARTPaginatedResult.m',
	'ARTRest.m',
	'ARTRestChannel.m',
	'ARTRestChannels.m',
	'ARTRestPresence.m',
]

import re
r = re.compile('^ ?[-\+] ?(\([^\{]+\))[a-zA-Z_]+ ?\{')

for fname in files:
	n = ''
	with open(fname, 'r') as f:
		inmethod = False
		for line in f:
			if inmethod:
				if line.startswith('}'):
					inmethod = False
					n += '} ART_TRY_OR_REPORT_CRASH_END\n'
			n += line
			if not inmethod:
				m = r.match(line)
				if m is not None:
					inmethod = True
					n += 'ART_TRY_OR_REPORT_CRASH_START(%s) {\n' % ('self' if fname == 'ARTRest.m' else '_rest')
	with open(fname, 'w') as f:
		f.write(n)
