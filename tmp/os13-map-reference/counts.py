import json,collections
f=json.load(open('maps/os13/fixtures.json'));print(collections.Counter(i['path'] for i in f).most_common(15))
