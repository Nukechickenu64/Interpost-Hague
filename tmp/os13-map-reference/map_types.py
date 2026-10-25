import re
s=open('maps/alpha/alpha.dmm').read();paths=sorted(set(re.findall(r'/obj/[\w/]+',s)))
for term in ['apc','modcon','medical','chem','supply','sink','rack','toilet','security','secure','protolathe','communic','card','latejoin','spawn']:
 print(term, [p for p in paths if term in p][-20:])
