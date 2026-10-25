from PIL import Image
from pathlib import Path
import re
for p in Path('icons/os13').rglob('*.dmi'):
 try:s=re.findall(r'state = "(.*?)"',Image.open(p).info.get('Description',''))
 except:continue
 found=[k for k in s if any(w in k.lower() for w in ('bridge','medbay','armory','hydro','cargo','signbar','sci','chapel'))]
 if found:print(str(p),found[:25])
