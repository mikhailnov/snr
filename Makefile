PREFIX ?= /usr
BINDIR ?= $(PREFIX)/bin
MANDIR ?= $(PREFIX)/share/man

all:
	echo "Nothing to do, run make install"

install:
	mkdir -p $(DESTDIR)/$(BINDIR)
	mkdir -p $(DESTDIR)/etc
	mkdir -p $(DESTDIR)/$(MANDIR)/man1/
	install -m0755 snr.sh $(DESTDIR)/$(BINDIR)/snr
	install -m0644 snr.conf $(DESTDIR)/etc/snr.conf
	md2man -output $(DESTDIR)/$(MANDIR)/man1/snr.1 README.md
