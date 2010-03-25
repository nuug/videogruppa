DESTDIR =
prefix = /usr
bindir = $(prefix)/bin
cgibindir = $(prefix)/lib/cgi-bin

INSTALL      = install -m755
INSTALL_DATA = install -m644

all:

install:
	$(INSTALL) -d $(DESTDIR)$(bindir)
	$(INSTALL) bin/scheduler $(DESTDIR)$(bindir)/frikanalen-scheduler
	$(INSTALL) bin/frikanalen-tonostats $(DESTDIR)$(bindir)/frikanalen-tonostats

	$(INSTALL) -d $(DESTDIR)$(cgibindir)
	$(INSTALL) cgi-bin/fetchvideo.cgi cgi-bin/frontpage.cgi $(DESTDIR)$(cgibindir)

clean:
