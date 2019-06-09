PREFIX ?= /usr
BINDIR ?= $(PREFIX)/bin

all:
	echo "Nothing to do, run make install"

install:
	mkdir -p $(DESTDIR)/$(BINDIR)
	install -m0755 snr.sh $(DESTDIR)/$(BINDIR)/snr
