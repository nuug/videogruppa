DESTDIR =
prefix = /usr
bindir = $(prefix)/bin

INSTALL      = install -m755
INSTALL_DATA = install -m644

all:

install:
	$(INSTALL) -d $(DESTDIR)$(bindir)
	$(INSTALL) bin/scheduler $(DESTDIR)$(bindir)/frikanalen-scheduler

clean:
