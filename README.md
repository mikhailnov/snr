# snr — systemd-nspawn runner

## About snr

Simple wrapper to quickly run systemd-nspawn containers with support to:

* run graphical applications inside container
* have full access to videocard
* have working sound input and output
* bind to network bridge
* specify any other options for systemd-nspawn

## Usage examples

Some usage examples:

* `snr rosa-2016.1`
* `snr rosa-2016.1 -b`
* `NW=0 rosa-2016.1 -b`
* `NW=0 rosa-2016.1 --bind=/tmp/rosa`

where `rosa-2016.1` is a directory inside `/var/lib/machines` or inside the current directory.

All options, including `DIR=/var/lib/machines`, can be overriden via envoronmental variables or in `/etc/snr.conf`.

