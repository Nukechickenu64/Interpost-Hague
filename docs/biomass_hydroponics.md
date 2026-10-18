Vat hydroponics follows the Hydroponics section of the [Lifeweb Logistics Officer guide](https://lfwb.at/index.php?title=Logistics_Officer&oldid=3443).

On Alpha, four vats replace the plant trays in the upper hydroponics room. The north wall has a culture dispenser and Hydroponics Console. The Biomass Press is in the lower room, and the Food Processor is on the kitchen's recipe-book counter. Botanist lockers contain skimmers and starter cultures. Research's head scientist locker contains a Water Chip; Research can also fabricate replacements through the existing engineering research design.

1. Insert the Water Chip into the Hydroponics Console. Click the console with an empty hand to open its live vat-status screen, then select **Fill empty vats** to supply vats in the same room and on the same deck. Alt-click the console to recover its chip.
2. Once a vat is full, add one yeast packet and one glig, in either order. The culture dispenser and cargo supply crates provide replacements.
3. Wait for the flashing red indicator. Use an empty skimmer to mix the foam. Growth stays stopped until someone mixes it; repeat whenever red flashes.
4. When green flashes, use an empty skimmer to scoop one portion of goo.
5. Use the loaded skimmer on the Biomass Press. After it finishes, click with an empty hand to collect the brick. Repeat for the remaining goo.
6. Bring bricks to the Food Processor. Click it to choose Burger, Sausage, or Wafers, insert a brick, then collect the finished meal. Alternatively, insert bricks into a cloning pod to replenish its existing feedstock supply.

The guide does not give numerical timings or yields. This implementation uses a 10-second fill, three required mixes separated by 30-second growth intervals (including one final interval after the third mix), three scoops per batch, and five seconds per pressing or food-processing operation. Each brick supplies 50 cloning biomass; a full batch supplies the existing 150-unit clone cost. A harvested vat needs fresh water, yeast, and glig for its next batch. Power loss pauses machinery; removing the chip pauses filling. A full skimmer cannot mix or harvest again until emptied.

The supplied `vats.dmi` provides vat stages, `os13hydroitems.dmi` provides the skimmer and press, and `hydroponics.dmi` provides the flashing red/green indicators. Existing OS13 cooking/harvest sprites provide yeast, glig, and biomass. Other maps' conventional plant trays keep their existing behavior.

Focused server tests are in `code/unit_tests/biomass_tests.dm`. Compile `biomass_regression.dme` with DreamMaker and run its DMB with DreamDaemon to exercise chip handling, power pauses, recipe consumption, mandatory mixing, bounded harvesting, pressing, food shapes, cloning feedstock, and actual machinery processing. The wrapper enables machinery during the test setup runlevel; production runlevels are unchanged.
