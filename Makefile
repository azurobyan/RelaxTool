.PHONY: all clean install uninstall

SUBDIRS = approximator smoother solver
DATA_DIR = /var/lib/relaxtool

all:
	@for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir; \
	done

install:
	@for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir install; \
	done
	# Создаем директории для данных
	sudo install -d -m 1777 $(DATA_DIR)/input
	sudo install -d -m 1777 $(DATA_DIR)/output
	@echo "Data directories created at:"
	@echo "  Input: $(DATA_DIR)/input"
	@echo "  Output: $(DATA_DIR)/output"

uninstall:
	@for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir uninstall; \
	done
	sudo rm -rf $(DATA_DIR)
	@echo "Data directories removed: $(DATA_DIR)"

clean:
	@for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir clean; \
	done
