.POSIX:
.PHONY: all help install deinstall reinstall clean

PORTSDIR = /usr/ports
PORTS    = x11/sterm x11/dmenu x11/slock x11/slstatus x11-wm/dwm x11/xdm
PKGS     = sterm dmenu slock slstatus dwm xdm
DOTS     = .xinitrc .Xresources .config/fontconfig/fonts.conf \
           .local/share/dot.xbm
XDMDIR   = /usr/local/etc/X11/xdm

all:
	for p in $(PORTS); do \
		make -C $(PORTSDIR)/$$p install-missing-packages build || \
		    exit 1; \
	done

help:
	@echo 'usage: make [install | reinstall | deinstall | clean | help]'

install:
	pkg install -A $$(cat pkg.list)
	for p in $(PORTS); do \
		make -C $(PORTSDIR)/$$p install-missing-packages install || \
		    exit 1; \
	done
	pkg lock -y $(PKGS)
	install -m 644 xdm/Xresources $(XDMDIR)/Xresources.desktop
	install -m 644 xdm/Xservers xdm/freebsd.xpm home/.local/share/dot.xbm \
	    $(XDMDIR)
	install -m 755 xdm/Xsetup_0 $(XDMDIR)
	grep -q Xresources.desktop $(XDMDIR)/Xresources || \
	    echo '#include "Xresources.desktop"' >> $(XDMDIR)/Xresources
	sysrc xdm_enable=YES
	su $$(stat -f %Su .) -c 'for f in $(DOTS); do \
		if [ -e ~/$$f ]; then echo "~/$$f already installed"; \
		else mkdir -p "$$(dirname ~/$$f)" && cp home/$$f ~/$$f; fi; \
	done; \
	if [ -e ~/.xsession ]; then echo "~/.xsession already installed"; \
	else ln -s .xinitrc ~/.xsession; fi'

deinstall:
	su $$(stat -f %Su .) -c 'for f in $(DOTS); do \
		if cmp -s home/$$f ~/$$f; then rm ~/$$f; \
		elif [ -e ~/$$f ]; then echo "~/$$f changed, kept"; fi; \
	done; \
	if [ "$$(readlink ~/.xsession)" = .xinitrc ]; then rm ~/.xsession; fi'
	-sysrc -x xdm_enable
	-sed -i '' '/^#include "Xresources.desktop"$$/d' $(XDMDIR)/Xresources
	-cp $(XDMDIR)/Xservers.sample $(XDMDIR)/Xservers
	-cp $(XDMDIR)/Xsetup_0.sample $(XDMDIR)/Xsetup_0
	rm -f $(XDMDIR)/Xresources.desktop $(XDMDIR)/freebsd.xpm \
	    $(XDMDIR)/dot.xbm
	-pkg unlock -y $(PKGS)
	for p in $(PORTS); do make -C $(PORTSDIR)/$$p deinstall; done
	pkg autoremove

reinstall: deinstall install

clean:
	for p in $(PORTS); do make -C $(PORTSDIR)/$$p clean; done
