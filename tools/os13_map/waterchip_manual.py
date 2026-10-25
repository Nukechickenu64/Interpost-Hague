"""Retired provisional reconstruction. Do not use to write a map.

Its unverified placements were rejected. New map work is entered directly in
the DMM only after manual frame-to-tile confirmation.
"""
from pathlib import Path
import hashlib
import json
import re
import string

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'os13.dmm'
OUT = ROOT / 'maps/os13/waterchip-manual.dmm'


def atoms(text):
    result, start, depth, quote = [], 0, 0, None
    for i, ch in enumerate(text):
        if quote:
            if ch == quote and (i == 0 or text[i-1] != '\\'):
                quote = None
        elif ch in ('"', "'"):
            quote = ch
        elif ch in '({':
            depth += 1
        elif ch in ')}':
            depth -= 1
        elif ch == ',' and depth == 0:
            result.append(text[start:i].strip())
            start = i+1
    result.append(text[start:].strip())
    return result


def read_map(text):
    definitions = dict(re.findall(r'^"([A-Za-z]+)" = \((.*?)\)\s*$', text, re.M | re.S))
    width = len(next(iter(definitions)))
    grid = {}
    for b in re.finditer(r'\((\d+),(\d+),(\d+)\) = \{"(.*?)"\}', text, re.S):
        x, y, z = map(int, b.group(1,2,3))
        rows = b[4].strip().splitlines()
        for j, row in enumerate(rows):
            assert len(row) % width == 0
            for i in range(0, len(row), width):
                p = x+i//width, y+len(rows)-1-j, z
                assert p not in grid
                grid[p] = atoms(definitions[row[i:i+width]])
    return grid


def build():
    raise SystemExit('Disabled: restore only from reviewed manual DMM edits; do not regenerate.')
    source = SOURCE.read_text()
    grid = read_map(source)
    original = {p: list(a) for p, a in grid.items()}
    log = []

    def replace_turf(x, y, state, evidence):
        p = x,y,4
        grid[p] = [('/turf/simulated/floor/fixed/os13/floors/state_'+state)
                   if a.startswith('/turf/') else a for a in grid[p]]
        log.append(dict(position=p, action='floor', state=state, evidence=evidence))

    def put(x, y, path, evidence, **props):
        p = x,y,4
        spec = path
        if props:
            spec += '{' + '; '.join(f'{k} = {v}' for k,v in props.items()) + '}'
        assert spec not in grid[p], (p,spec)
        grid[p].insert(0, spec)
        log.append(dict(position=p, action='object', atom=spec, evidence=evidence))

    def visual(x, y, icon, state, name, evidence, **props):
        put(x,y,'/obj/structure',evidence,icon="'"+icon+"'",
            icon_state=json.dumps(state),name=json.dumps(name),
            anchored=1,density=0,**props)

    decor = 'icons/os13/objects/objects/orbital_decor.dmi'
    floors = 'icons/os13/turf/turf/floors.dmi'
    ev_office = [0,10,65]
    # Five-by-four office, with recessed corners in its southern row.
    for y in (104,105,106):
        for x in range(98,103):
            replace_turf(x,y,'os11' if x in (98,102) else 'os3',ev_office)
    for x in (99,100,101):
        replace_turf(x,103,'os3',ev_office)
    # The two southern corner tiles are walls, visible clearly at 01:05.
    for x,mask in ((98,10),(102,6)):
        p=x,103,4
        grid[p]=[a for a in grid[p] if not a.startswith('/turf/')]
        grid[p].insert(0,f'/turf/simulated/wall/os13/wwalls/state_rwall{mask}')
        log.append(dict(position=p,action='wall',evidence=[65]))
    # Reuse the real console behavior; visual identity is the supplied scanner.
    put(100,106,'/obj/machinery/computer/cryopod',ev_office,
        icon="'"+decor+"'",icon_state='"scanner"',density=1)
    closet_icon = 'icons/os13/objects/objects/closet.dmi'
    def closet(x,y,closed,opened,ev,is_open=False):
        put(x,y,'/obj/structure/closet',ev,icon="'"+closet_icon+"'",
            icon_state=json.dumps(opened if is_open else closed),
            icon_closed=json.dumps(closed),icon_opened=json.dumps(opened),
            opened=int(is_open),density=int(not is_open),anchored=1)
    closet(98,106,'nt','ntopen',ev_office)
    put(102,106,'/obj/machinery/vending/coffee/os13_reference',[65])
    for x,y,ev in [(100,104,ev_office),(100,100,[0,10]),(106,100,[10,30]),
                   (106,105,[20,55])]:
        put(x,y,'/obj/machinery/floor_light/os13',ev)
    # Locker room: individually checked against 00:20 and 00:55.
    # Leave the perforated hatch tiles unchanged until their art is identified.
    ev_lockers=[20,55]
    for y in (103,104,105,107,108):
        for x in range(104,109):
            replace_turf(x,y,'os4',ev_lockers)
    for x,y in [(106,108),(104,105),(108,105)]:
        replace_turf(x,y,'osb1',ev_lockers)
    for x,y in [(105,106),(107,106),(106,103)]:
        replace_turf(x,y,'os3',ev_lockers)
    for x in (104,108):
        closet(x,108,'tnc2','tnc2open',ev_lockers,True)
        closet(x,107,'tnc','tncopen',ev_lockers,True)
    closet(104,104,'emergency','emergencyopen',ev_lockers,True)
    closet(104,103,'emergency','emergencyopen',ev_lockers)
    for y in (103,104):
        closet(108,y,'tnc','tncopen',ev_lockers,True)
    # Square grilles are overlays, leaving the underlying floor visible.
    for y in (104,107):
        visual(106,y,'icons/os13/objects/objects/structures.dmi','grille',
               'square floor grille (approximate art)',ev_lockers,
               transform='matrix(0.5, 0, 0, 0, 0.5, 0)')
    visual(105,109,'icons/os13/objects/objects/structures.dmi','omirror',
           'wall mirror',ev_lockers)
    # Visible circular wall lamps. Functional lighting requires a later pass;
    # these are deliberately recorded as visual fixtures.
    for x,y,ev in [(97,105,ev_office),(103,105,ev_office),
                    (103,107,ev_lockers),(109,105,ev_lockers),(109,103,ev_lockers),
                    (98,97,[0,10]),(102,97,[0,10]),(106,97,[10,30])]:
        visual(x,y,decor,'wall1','wall lamp (visual reference)',ev)
    # North corridor, manually aligned in 00:55, 01:00, 01:05 and 01:10.
    # Each row lists observed floor tiles west-to-east, not unseen room fills.
    # 0 = cross-braced dark floor; 4 = four-panel gray floor.
    corridor_rows = {
        112: (92, '44440404440444'),
        111: (92, '00000400000004'),
        110: (92, '0000040000000000000'),
        109: (99, '000'),
        108: (99, '000'),
    }
    for y,(start,row) in corridor_rows.items():
        for offset,code in enumerate(row):
            x=start+offset
            assert any(a.startswith('/turf/simulated/floor') for a in grid[x,y,4]), (x,y)
            replace_turf(x,y,'n00' if code=='0' else 'os4',[55,60,65,70])
    for x,y in [(97,111),(105,111)]:
        put(x,y,'/obj/machinery/floor_light/os13',[60,65,70])
    for x,y in [(100,111),(100,108)]:
        put(x,y,'/obj/structure/os13_walkway_bracing',[60,65,70])
    for x in (99,101):
        replace_turf(x,109,'os3',[65,70])
    # Passage south to the scanner office, and the locker-room north exit.
    for x,y in [(99,107),(106,109)]:
        replace_turf(x,y,'os4',[55,65,70])
        put(x,y,'/obj/machinery/door/os13_office',[55,65,70])
    put(97,113,'/obj/machinery/door/airlock/os13_corridor',[65,70])
    put(94,113,'/obj/machinery/door/airlock/os13_maintenance',[70])
    put(98,113,'/obj/structure/sign/os13_reference_deck',[65,70])
    # These wall strips have actual powered lighting, not decorative proxies.
    for x,y in [(96,109),(104,109),(108,109)]:
        put(x,y,'/obj/machinery/light/small/os13_green_strip',[55,60,70],dir=1)
    # Hand-transcribed connections of the visible office and locker-room walls.
    # Bitmask is N=1, S=2, E=4, W=8 in the supplied rwall sprite set.
    wall_states = {
        (97,103):3,(97,104):3,(97,105):3,(97,106):3,(97,107):6,
        (98,107):12,(100,107):12,(101,107):12,(102,107):12,
        (103,103):3,(103,104):3,(103,105):3,(103,106):3,
        (103,107):11,(103,108):3,(103,109):6,
        (104,109):12,(105,109):12,(107,109):12,(108,109):12,
        (109,109):10,(109,108):3,(109,107):3,(109,106):3,
        (109,105):3,(109,104):3,(109,103):3,
        (97,102):13,(98,102):13,(102,102):13,
    }
    for (x,y),mask in wall_states.items():
        p=x,y,4
        assert any(a.startswith('/turf/simulated/wall') for a in grid[p]),p
        grid[p]=[f'/turf/simulated/wall/os13/wwalls/state_rwall{mask}'
                 if a.startswith('/turf/') else a for a in grid[p]]
        log.append(dict(position=p,action='wall',state=f'rwall{mask}',evidence=[0,20,55,65,70]))

    # Existing pods and the three-window anchor remain intact.
    for x in (98,102):
        for y in (99,100):
            assert any(a.startswith('/obj/machinery/cryopod') for a in grid[x,y,4])
    changed = {p for p in grid if grid[p] != original[p]}
    assert {p[2] for p in changed} <= {4}
    # Serialize without altering any cells outside the explicit observations.
    definitions = {}
    keys = {}
    alphabet = string.ascii_lowercase+string.ascii_uppercase
    for p,a in grid.items():
        signature = tuple(a)
        if signature not in definitions:
            n=len(definitions)
            assert n < len(alphabet)**2
            definitions[signature] = alphabet[n//52]+alphabet[n%52]
        keys[p]=definitions[signature]
    output=['// Manual water-chip opening-section reconstruction; incomplete.']
    output += ['"'+key+'" = (\n'+',\n'.join(a)+')' for a,key in definitions.items()]
    columns={}
    for x,y,z in grid:
        columns.setdefault((x,z),[]).append(y)
    for (x,z),ys in sorted(columns.items(),key=lambda a:(a[0][1],a[0][0])):
        ys.sort(reverse=True)
        assert ys == list(range(max(ys),min(ys)-1,-1))
        output.append(f'({x},{min(ys)},{z}) = {{"\n'+ '\n'.join(keys[x,y,z] for y in ys)+'\n"}')
    OUT.write_text('\n'.join(output)+'\n')
    reread=read_map(OUT.read_text())
    assert reread==grid, 'DMM round-trip changed map contents'
    manifest=dict(status='incomplete opening-section manual pass',source=str(SOURCE),
        source_sha256=hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
        starting_z=4,anchor=[100,102,4],changed_z_levels=sorted({p[2] for p in changed}),
        review='Selected stills from 00:00-01:10; NOT every video frame reviewed',
        changed_cells=len(changed),operations=log,
        limitations=['No full-video reconstruction','Remaining doors and signs not yet transcribed',
            'Unidentified perforated floor tiles retain template art',
            'Small round wall lamps remain visual only','No live client validation'])
    OUT.with_suffix('.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print(f'{OUT}: {len(changed)} changed cells; {len(log)} manual observations; DMM round-trip passed')


if __name__ == '__main__':
    raise SystemExit('Disabled: use direct, frame-verified DMM edits only.')
