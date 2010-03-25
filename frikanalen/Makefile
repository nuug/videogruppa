DESTDIR =
prefix = /usr
bindir = $(prefix)/bin
cgibindir = $(prefix)/lib/cgi-bin
wwwdir = $(prefix)/share/frikanalen/www

INSTALL      = install -m755
INSTALL_DATA = install -m644

all:

install:
	$(INSTALL) -d $(DESTDIR)$(bindir)
	$(INSTALL) bin/scheduler $(DESTDIR)$(bindir)/frikanalen-scheduler
	$(INSTALL) bin/frikanalen-tonostats $(DESTDIR)$(bindir)/frikanalen-tonostats

	$(INSTALL) -d $(DESTDIR)$(cgibindir)
	$(INSTALL) cgi-bin/fetchvideo.cgi cgi-bin/frontpage.cgi $(DESTDIR)$(cgibindir)

	$(INSTALL) -d $(DESTDIR)$(wwwdir)
	for file in bullet.gif bullet.png hide.js lage-tv.png logo.png meny1.png meny.png \
		om.png se.png style1.css style.css ; do \
		$(INSTALL_DATA) cgi-bin/$$file $(DESTDIR)$(wwwdir)/.; \
	done

clean:
