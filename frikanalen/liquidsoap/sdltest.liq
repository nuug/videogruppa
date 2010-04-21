set("log.file.path","/tmp/sdltest.log")
set("frame.video.channels",1)
# http://www.nuug.no/pub/video/frikanalen/1241.ogv = /tmp/input.ogv
output.alsa(output.sdl(single("/tmp/input.ogv")))
