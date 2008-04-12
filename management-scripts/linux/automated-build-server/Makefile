# Automated Build Server Makefile
#
# The default target is install, which requires you to be root.

# EDIT ME: You'll need to set this to the path of your BYOND bin directory.
BYOND_PATH="/usr/local/byond/bin"

help:
	@echo "In order to install the Automated Build Server, please edit:"; \
	echo ""; \
	echo "	configuration.sh"; \
	echo "	Makefile"; \
	echo ""; \
	echo "To confirm the paths you wish to install to, then run:"; \
	echo ""; \
	echo "	make prereq-checks"; \
	echo ""; \
	echo "To ensure you meet all the pre-requisites, then finally run:"; \
	echo ""; \
	echo "	make install"; \
	echo ""; \
	echo "NB: To stop the server running automatically on repo update, run:"; \
	echo ""; \
	echo "	make remove-crontab"; \
	echo ""; \
	echo "A full uninstall is currently in the works."

clean:
	@echo "[INFO] == Cleaning. == "
	@sed -i -e "s|source .*configuration.sh|source configuration.sh|" build-version.sh load-version.sh rotate-logs.sh svn-update.sh
	@echo "[INFO] Reset script paths."
	@rm -f *.tmp 2> /dev/null
	@echo "[INFO] Removed temporary files."

prereq-checks:
	@echo "[INFO] == Performing pre-requisite checks. == "
	@MYID=`whoami`; \
	if [ "root" != $$MYID ]; then \
		echo "[ERROR] You need to be root to install."; \
		exit 1; \
	fi
	@if [ -d ${BYOND_PATH} ]; then \
		echo "[INFO] BYOND directory confirmed."; \
	else \
		echo "[ERROR] You need to have /usr/local/byond/bin point to your BYOND bin."; \
	fi
	@if [ -x ${BYOND_PATH}/DreamMaker ]; then \
		echo "[INFO] DreamMaker confirmed as executable."; \
	else \
		echo "[ERROR] DreamMaker is not executable."; \
	fi
	@if [ -x ${BYOND_PATH}/DreamDaemon ]; then \
		echo "[INFO] DreamDaemon confirmed as executable."; \
	else \
		echo "[ERROR] DreamDaemon is not executable."; \
	fi
	@${BYOND_PATH}/DreamDaemon -version | grep 'BYOND 4.0' > /dev/null; \
	if [ $$? -ne 0 ]; then \
		echo "[ERROR] You are not running BYOND 4.0."; \
	else \
		echo "[INFO] Running BYOND 4.0."; \
	fi
	@svn help > /dev/null; \
	if [ $$? -ne 0 ]; then \
		echo "[ERROR] You do not have SVN on your PATH."; \
	else \
		echo "[INFO] SVN found."; \
	fi
	@chmod 755 *.sh
	@echo "[INFO] Corrected any script permissions issues."

install: install-scripts install-crontab clean

install-crontab:
	@echo "[INFO] == Installing crontab, to schedule update check. == "
	@crontab -l > crontab.tmp 2> /dev/null; \
	if [ $$? -eq 0 ]; then \
		crontab -r; \
	fi
	@source configuration.sh; \
	cat crontab.tmp | grep -v 'svn-update.sh' > crontab2.tmp; \
	mv -f crontab2.tmp crontab.tmp; \
	echo "*/5 * * * * $${SCRIPTS_PATH}/svn-update.sh" >> crontab.tmp
	@crontab crontab.tmp
	@echo "[INFO] Installed crontab."

install-scripts: prereq-checks clean
	@echo "[INFO] == Installing scripts. == "
	@source configuration.sh; \
	if [ -e $${SCRIPTS_PATH} ]; then \
		echo "[WARNING] Found something at $${SCRIPTS_PATH}, clobbering it."; \
		rm -rf $${SCRIPTS_PATH}; \
	fi
	@source configuration.sh; \
	mkdir -p $${SCRIPTS_PATH}
	@echo "[INFO] Made server script directory."
	@source configuration.sh; \
	if [ -e $${SERVER_PATH} ]; then \
		echo "[WARNING] Found something at $${SERVER_PATH}, clobbering it."; \
		rm -rf $${SERVER_PATH}; \
	fi
	@source configuration.sh; \
	mkdir -p $${SERVER_PATH}
	@echo "[INFO] Made server execution directory."
	@source configuration.sh; \
	if [ -e $${LOCAL_SOURCE_PATH} ]; then \
		echo "[WARNING] Found something at $${LOCAL_SOURCE_PATH}, clobbering it."; \
		rm -rf $${LOCAL_SOURCE_PATH}; \
	fi
	@source configuration.sh; \
	svn co $${REMOTE_SOURCE_PATH} $${LOCAL_SOURCE_PATH} > /dev/null
	@echo "[INFO] Checked out repository."
	@source configuration.sh; \
	sed -i -e "s|source configuration.sh|source $${SCRIPTS_PATH}/configuration.sh|" build-version.sh load-version.sh rotate-logs.sh svn-update.sh
	@echo "[INFO] Prepared script paths."
	@source configuration.sh; \
	cp -f configuration.sh $${SCRIPTS_PATH}/configuration.sh; \
	cp -f build-version.sh $${SCRIPTS_PATH}/build-version.sh; \
	cp -f load-version.sh $${SCRIPTS_PATH}/load-version.sh; \
	cp -f rotate-logs.sh $${SCRIPTS_PATH}/rotate-logs.sh; \
	cp -f svn-update.sh $${SCRIPTS_PATH}/svn-update.sh; \
	echo "[INFO] Copied scripts to $${SCRIPTS_PATH}."

remove-crontab:
	@echo "[INFO] == Removing crontab, to schedule update check. == "
	@crontab -l > crontab.tmp 2> /dev/null; \
	if [ $$? -eq 0 ]; then \
		crontab -r; \
	fi
	@source configuration.sh; \
	cat crontab.tmp | grep -v 'svn-update.sh' > crontab2.tmp; \
	mv -f crontab2.tmp crontab.tmp; \
	crontab crontab.tmp
	@echo "[INFO] Removed crontab."
	@rm -f crontab.tmp
