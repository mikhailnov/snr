PREFIX ?= /usr
BINDIR ?= $(PREFIX)/bin

all:
	echo "Nothing to do, run make install"

install:
	mkdir -p $(DESTDIR)/$(BINDIR)
	mkdir -p $(DESTDIR)/etc
	install -m0755 snr.sh $(DESTDIR)/$(BINDIR)/snr
	install -m0644 snr.conf $(DESTDIR)/etc/snr.conf
