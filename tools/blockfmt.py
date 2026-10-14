data = open('maps/alpha/alpha.dmm', encoding='utf-8', errors='replace').read()
midx = data.find('(1,1,1) =')
pos1 = midx
# find start of z2 group
pos2 = data.find('\n(1,1,2) =')
print('z1 block between', pos1, pos2)
print(repr(data[pos2-120:pos2+60]))