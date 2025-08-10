INSTALL_DIR := /usr/local/bin
CONFIG_DIR := /etc/parser
SHARE_DIR := /usr/local/share/parser

PYTHON_SCRIPT := src/plotter.py
SCRIPTS := $(wildcard scripts/*)
CONFIGS := $(wildcard data/*)

install:
	# Python скрипт
	sudo install -d $(DESTDIR)$(INSTALL_DIR)
	sudo install -m 755 $(PYTHON_SCRIPT) $(DESTDIR)$(INSTALL_DIR)/parser_plotter
	
	# Конфиги
	sudo install -d $(DESTDIR)$(CONFIG_DIR)
	sudo install -m 644 $(CONFIGS) $(DESTDIR)$(CONFIG_DIR)/
	
	# Скрипты
	sudo install -d $(DESTDIR)$(SHARE_DIR)/scripts
	sudo install -m 755 $(SCRIPTS) $(DESTDIR)$(SHARE_DIR)/scripts
	sudo ln -sf $(SHARE_DIR)/scripts/Result_parser.sh $(DESTDIR)$(INSTALL_DIR)/parser_main

uninstall:
	sudo rm -f $(DESTDIR)$(INSTALL_DIR)/parser_plotter
	sudo rm -rf $(DESTDIR)$(CONFIG_DIR)
	sudo rm -rf $(DESTDIR)$(SHARE_DIR)

clean:
	@echo "Nothing to clean for parser"
