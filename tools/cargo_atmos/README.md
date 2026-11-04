# Cargo elevator breathing regression

Human room-air breaths used 12 liters while internals and lung gas thresholds
used `BREATH_VOLUME` (0.5 liters). This exaggerated CO2 exposure by 24 times and
also made the low-air check accept air far below its intended safe quantity.
Room breaths now use the same volume as internals and the lung thresholds.

On OS13 Classic, the original code produced oxygen deprivation in three of nine
occupied cargo rooms after 200 controlled breathing/atmosphere cycles, including
the zone containing the lower mining elevator. With the corrected volume, all
nine occupants had zero oxygen deprivation after the same cycles. This is a
native simulation check; it does not certify every live round or lift movement.

The permanent target checks normal air, modest cargo CO2, thin air, low oxygen,
dangerous CO2, vacuum, and gas conservation. It then places three humans on and
beside the lower elevator and runs 200 breathing/atmosphere cycles with the
production map's controls and vents. Random vent malfunctions are disabled for
that isolated test. It exits without starting a round.

From the repository root, with the installed BYOND tools:

```powershell
& 'C:\Program Files (x86)\BYOND\bin\dm.exe' cargo_atmos_regression.dme
& 'C:\Program Files (x86)\BYOND\bin\dd.exe' cargo_atmos_regression.dmb -invisible -trusted -close
python tools/cargo_atmos/check.py
```

The log is `tmp/cargo-atmos/regression.log`. Restart a running production world
after rebuilding `Interpost-Hague.dme` to load the fix.
