set("log.file.path","/tmp/test.log")
set("frame.video.channels",1)
set("frame.video.width",384)
set("frame.video.height",288)
backup = single("/tmp/input.ogv")
list = playlist("playlist.txt")
stream = fallback([list, backup])

output.icecast.theora(host = "voip.nuug.no", port = 8000,
    user = "source", password = "secret",
    mount = "liq.ogv", stream)

#output.file.theora(reopen_on_metadata=true, "/tmp/output.ogv",stream)
