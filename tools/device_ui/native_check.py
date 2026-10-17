"""Generate a small Dream Seeker integration test for the physical window shell.

Run check.py first, compile native.dme, start its DMB with DreamDaemon, then
connect a test Dream Seeker. It checks native properties and clicks the real X.
The test world shuts down on completion or after 30 seconds.
"""
from pathlib import Path

OUT = Path(__file__).resolve().parents[2] / 'tmp/device-ui-check'
harness = (OUT / 'check.dme').read_text()
start = harness.index('/world/New()')
end = harness.index('/proc/cyberdeck_fixtures()')
harness = harness[:start] + harness[end:]
harness = harness.replace('/datum/asset/proc/send(user)', '''/datum/asset/proc/send(mob/user)
    for(var/name in assets)
        user << browse_rsc(assets[name], name)''')
harness = harness.replace('/client/proc/windowclose(atomref)', '''/client/proc/windowclose(atomref)
    callback_received = TRUE
    verify(atomref == "\\ref[test_host]", "Close callback must receive the original host reference")
    // Simulate a legacy Topic handler that renders again while being closed.
    mob.machine = test_host
    src << browse("Legacy callback reopened", "window=device_test")''')
harness += r'''
/world/New()
    ..()
    world.log << "NATIVE DEVICE UI: waiting for test client"
    spawn(300)
        world.log << "NATIVE DEVICE UI: FAIL (client timed out)"
        shutdown()

/client
    var/obj/machinery/test_host
    var/callback_received = FALSE

/client/New()
    . = ..()
    spawn(5)
        test_host = new
        test_host.icon = 'icons/obj/computer.dmi'
        test_host.icon_state = "os13_rdcomp"
        test_host.name = "Native device test"
        mob.machine = test_host
        src << browse("Old bordered window", "window=device_test;size=600x400;can_resize=1;titlebar=1")
        sleep(2)
        var/html = {"<!DOCTYPE html><html><head><title>Native device test</title></head><body><p>Native close and border regression</p><script>function testClose(){document.getElementById('device-close').click();}setTimeout(function(){window.location.href='byond://?device_ready=1';},750);</script></body></html>"}
        device_ui_browse(mob, html, "window=device_test;size=600x400", test_host)

/client/Topic(href, list/href_list)
    if(!href_list["device_ready"])
        return ..()
    verify(winget(src, "device_test", "titlebar") == "false", "Existing window titlebar must be removed")
    verify(winget(src, "device_test", "can-resize") == "false", "Native resize frame must be removed")
    verify(winget(src, "device_test.browser", "border") == "none", "Embedded browser must have no sunken border")
    var/inner_size = winget(src, "device_test", "size")
    var/outer_size = winget(src, "device_test", "outer-size")
    world.log << "Native size [inner_size], outer size [outer_size]"
    verify(inner_size == outer_size, "The native window must have zero non-client border")
    winset(src, "device_test", "size=640x440")
    verify(winget(src, "device_test", "size") == "640x440", "Programmatic bezel resizing must still work")
    src << output(null, "device_test.browser:testClose")
    spawn(15)
        verify(callback_received, "Clicking the real X must invoke the close verb without a prompt")
        verify(!mob.machine, "Close must stop dialog refresh subscriptions")
        verify(winget(src, "device_test", "is-visible") != "true", "Close callback must not leave the native window open")
        world.log << "NATIVE DEVICE UI: [failures ? "FAIL" : "PASS"]"
        shutdown()
'''
(OUT / 'native.dme').write_text(harness)
print(OUT / 'native.dme')
