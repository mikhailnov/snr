# snr — systemd-nspawn runner

## About snr

Simple wrapper to quickly run systemd-nspawn containers with support to:

* run graphical applications inside container
* have full access to videocard
* have working sound input and output
* bind to network bridge
* automatically set x86_32 "personality" when running 32 bit containers
* specify any other options for systemd-nspawn
* automatically uses `sudo` when being run not as root

## CLI syntax

`snr CONTAINER_NAME [additional CLI arguements passed directly to systemd-nspawn]`

## Usage examples

Some usage examples:

* `snr rosa-2016.1`
* `snr rosa-2016.1 -b`
* `NW=0 rosa-2016.1 -b`
* `NW=0 rosa-2016.1 --bind=/tmp/rosa`

`-b` (or `--boot`) means booting the container, not just chrooting into it. All options are passed to `systemd-nspawn(1)` without changes.

Run specific application, including graphical ones (`geany` as an example):

* `snr rosa-2016.1 -q geany`
* `snr rosa-2016.1 --bind=/tmp/rosa -q geany`
* `snr rosa-2016.1 -q "sudo -u user geany"`
* `snr rosa-2016.1 -q urpmi gedit`

where `rosa-2016.1` is a directory inside `/var/lib/machines` or inside the current directory.

## Options

All options can be set in `/etc/snr.conf` or `$PWD/snr.conf` or defined as environmental variables.

* `DIR` — directory where to look for containers, `/var/lib/machines` by default
* `NW` — reuse an existing network interface (usually a bridge)  
  If livbirtd is running, it creates `virbr0` interface, which is used by virtual machines. It can be used also for containers to get IP addresses via DHCP from the same network.  
  `NW=0` - disable binding to network bridge  
  `NW=1` - enable binding to network bridge  
  `NW=2` - force binding to network bridge even if not booting  
  If the container is not being booted (`-b | --boot`) and `NW` is not defined or is 0 or is 1, then it is set to `0`.
* `BRIDGE` — name of the network interface to use  
  If not defined, `snr` tries to use the first `virbr*` interface.
* `bind_options` — set a persistent list of mount-binded directories for `systemd-nspawn(1)`  
  Examples:  
  `--bind=/tmp/444` means "make a directory `/tmp/444` inside the container and make `/tmp/444` from the host be it"  
  `--bind=/tmp/444:/root/444` means "make a directory `/root/444` inside the container and make `/tmp/444` from the host be it"  
  `--bind=/tmp/444 --bind=/tmp/555:/root/555`
* `other_options` — list of any other CLI options for `systemd-nspawn(1)` which are always passed to it  
  When a container is run, options are appended in the following order:  
  `[bind_options]` `[other_options]` `[everything from snr cli]`  

## Feedback

Report bugs and send feedback to issues at [https://github.com/mikhailnov/snr](https://github.com/mikhailnov/snr).

Feel free to send pull requests or email patches to <mikhailnov@nixtux.ru>.
