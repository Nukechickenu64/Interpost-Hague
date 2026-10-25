from PIL import Image
import re
for p in ['icons/os13/turf/turf/walls.dmi','icons/os13/turf/turf/wallb.dmi','icons/os13/objects/objects/signs.dmi','icons/os13/objects/objects/signs2.dmi','icons/os13/objects/objects/ostable.dmi']:
 print(p,re.findall(r'state = "(.*?)"',Image.open(p).info.get('Description','')))
