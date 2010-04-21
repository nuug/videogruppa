set("log.file.path","/tmp/fulltest.log")
set("frame.video.channels",1)
# http://www.nuug.no/pub/video/frikanalen/1241.ogv = /tmp/input.ogv
stream = single("/tmp/input.ogv")
output.file.theora(reopen_on_metadata=true, "/tmp/output.ogv",stream)
# output.sdl(stream)
