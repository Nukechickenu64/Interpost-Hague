# Cyberdeck research

Insert a **blank technology disk** into the cyberdeck research console. Buckle a
technician into a cyberdeck chair within three tiles and equip a cyberdeck helmet.
The console operator selects the occupied chair and boots a research field.
You can boot yourself while seated in a chair beside the console. Keep the console
within arm's reach when using its controls yourself. A successful boot closes the
console window and moves your controls and view to the avatar.

Each dive creates an isolated, connected maze on its own z-level. Its playable
width and height are `13 + 2 × technology level` tiles. Repeated dives regenerate
the layout; released levels are reused. Mapping prepares at least four isolated
z-levels before the game starts, or one per mapped console if there are more than
four. Each has space for the largest research maze. Booting only carves the small
maze with tick-budget checks; it never expands the world or rebuilds z-level
metadata. If every archive is occupied, the console asks you to wait for a dive
to finish. The avatar is a simple animal with a flat,
four-direction snapshot of the technician's unclothed body, hair and species tail.
The physical body and its equipment stay in the chair.

Click each encrypted relay and reverse its hexadecimal shift. Wrong answers cost
10 avatar integrity; optional red ICE costs 20 when crossed. After decrypting all
relays, click the research data core and stand still for the three-second download.
Success returns the technician and records one technology on the inserted disk.
Eject it and import it at an R&D console. The next dive retrieves the next known
level in that field, up to level 20. Level-zero secret fields keep their existing
special sources.

Recall, the entry portal, loss of power, a broken connection, avatar death, console
destruction or disconnect return the technician without writing research. The
disk drive stays locked during a dive. Destroying a console ejects its disk.
The connection expires after `10 + technology level` minutes.

Destructive analysis now salvages materials and integrated circuit designs;
technology levels come from disks. BBS and infernal research remain alternative
disk sources. Engineering level 2 unlocks the water filtration chip at a protolathe,
replacing the previous automatic cyberdeck reward.

The Alpha map already contains a deck, chair and helmet; two blank disks are now
provided beside the helmet. More disks, helmets and console boards can be made
with starting research. Cyberdeck chairs can be built from five steel sheets.

The supplied `newcyber.dmi` is copied unchanged to `icons/misc/newcyber.dmi` and
provides the archive floor, firewall, relays, data core, recall portal and ICE.

Compile and run `cyberdeck_test.dme` for focused layout, Boot Level hyperlink and
lifecycle regressions. To also test a real client transferring into and out of an
avatar, start that test world with `-params "cyberdeck_client=1"` and connect a Dream
Seeker after initialization, before the tests begin. Use an isolated test server;
this opt-in test temporarily takes control of its first connected client.
For an in-game check, use two players (console operator and seated technician),
complete a dive, eject/import its disk, then verify the next level is offered.
Repeat with emergency recall, unbuckling, helmet removal and a console power cut.
Inspect human and tailed-species avatars in all four directions.
