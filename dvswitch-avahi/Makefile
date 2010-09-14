DESTDIR =
prefix = /usr
bindir = $(prefix)/bin

INSTALL = install -m755
INSTALL_DATA = install -m644

all:

clean:

install:
	$(INSTALL) -d $(DESTDIR)$(bindir)
	$(INSTALL) dvswitch-avahi dvsink-files-avahi $(DESTDIR)$(bindir)
	ln -s dvsink-files-avahi $(DESTDIR)$(bindir)/dvsink-command-avahi
	ln -s dvsink-files-avahi $(DESTDIR)$(bindir)/dvsource-dvgrab-avahi
	ln -s dvsink-files-avahi $(DESTDIR)$(bindir)/dvsource-firewire-avahi
	ln -s dvsink-files-avahi $(DESTDIR)$(bindir)/dvsource-v4l2-dv-avahi
	ln -s dvsink-files-avahi $(DESTDIR)$(bindir)/dvsource-alsa-avahi
