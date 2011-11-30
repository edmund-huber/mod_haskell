mod_wai.la: mod_wai.slo
	$(SH_LINK) -rpath $(libexecdir) -module -avoid-version  mod_wai.lo
DISTCLEAN_TARGETS = modules.mk
shared =  mod_wai.la
