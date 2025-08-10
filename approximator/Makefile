CXX := g++
EIGEN_INC := $(shell pkg-config --cflags eigen3 2>/dev/null || echo -I/usr/include/eigen3)
CXXFLAGS := -std=c++17 -O3 -Wall $(EIGEN_INC)

TARGET := exponential_fit
INSTALL_DIR := /usr/local/bin
CONFIG_DIR := /etc/approximator
SHARE_DIR := /usr/local/share/approximator
DOC_DIR := /usr/local/share/doc/approximator

SRC := src/exponential_fit.cpp
PYTHON_SCRIPT := src/visualize.py
SCRIPTS := $(wildcard scripts/*)
CONFIGS := $(wildcard data/*.json)
DOCS := doc/manual.txt

all: $(TARGET)

$(TARGET): $(SRC)
	$(CXX) $(CXXFLAGS) -o $@ $^

install:
	# Бинарник
	sudo install -d $(DESTDIR)$(INSTALL_DIR)
	sudo install -m 755 $(TARGET) $(DESTDIR)$(INSTALL_DIR)
	
	# Python скрипт
	sudo install -m 755 $(PYTHON_SCRIPT) $(DESTDIR)$(INSTALL_DIR)/approximator_visualize
	
	# Конфиги
	sudo install -d $(DESTDIR)$(CONFIG_DIR)
	sudo install -m 644 $(CONFIGS) $(DESTDIR)$(CONFIG_DIR)/
	
	# Скрипты и документация
	sudo install -d $(DESTDIR)$(SHARE_DIR)/scripts
	sudo install -m 755 $(SCRIPTS) $(DESTDIR)$(SHARE_DIR)/scripts
	sudo install -d $(DESTDIR)$(DOC_DIR)
	#sudo install -m 644 $(DOCS) $(DESTDIR)$(DOC_DIR)
	# Создаем симлинки для основных скриптов
	sudo ln -sf $(SHARE_DIR)/scripts/calculate.sh $(DESTDIR)$(INSTALL_DIR)/approximator_calculate
	sudo ln -sf $(SHARE_DIR)/scripts/run.sh $(DESTDIR)$(INSTALL_DIR)/approximator_run
	sudo ln -sf $(SHARE_DIR)/scripts/normalizer.sh $(DESTDIR)$(INSTALL_DIR)/approximator_normalize
	sudo ln -sf $(SHARE_DIR)/scripts/fit_exponential.sh $(DESTDIR)$(INSTALL_DIR)/approximator_fit
	sudo ln -sf $(SHARE_DIR)/scripts/parser_input.sh $(DESTDIR)$(INSTALL_DIR)/approximator_parser

uninstall:
	sudo rm -f $(DESTDIR)$(INSTALL_DIR)/$(TARGET)
	sudo rm -f $(DESTDIR)$(INSTALL_DIR)/approximator_visualize
	sudo rm -rf $(DESTDIR)$(CONFIG_DIR)
	sudo rm -rf $(DESTDIR)$(SHARE_DIR)
	sudo rm -rf $(DESTDIR)$(DOC_DIR)

clean:
	rm -f $(TARGET)
