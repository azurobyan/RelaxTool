CXX := g++
EIGEN_INC := $(shell pkg-config --cflags eigen3 2>/dev/null || echo -I/usr/include/eigen3)
CXXFLAGS := -std=c++11 -O3 -Wall $(EIGEN_INC)

TARGET := smoother
INSTALL_DIR := /usr/local/bin
CONFIG_DIR := /etc/smoother
SHARE_DIR := /usr/local/share/smoother

SRC := src/smoother.cpp
PYTHON_SCRIPT := src/plotter.py
SCRIPTS := $(wildcard scripts/*)
CONFIGS := $(wildcard data/*.json)

all: $(TARGET)

$(TARGET): $(SRC)
	$(CXX) $(CXXFLAGS) -o $@ $^

install:
	# Бинарник
	sudo install -d $(DESTDIR)$(INSTALL_DIR)
	sudo install -m 755 $(TARGET) $(DESTDIR)$(INSTALL_DIR)
	
	# Python скрипт
	sudo install -m 755 $(PYTHON_SCRIPT) $(DESTDIR)$(INSTALL_DIR)/smoother_plotter
	
	# Конфиги
	sudo install -d $(DESTDIR)$(CONFIG_DIR)
	sudo install -m 644 $(CONFIGS) $(DESTDIR)$(CONFIG_DIR)/
	
	# Скрипты
	sudo install -d $(DESTDIR)$(SHARE_DIR)/scripts
	sudo install -m 755 $(SCRIPTS) $(DESTDIR)$(SHARE_DIR)/scripts

uninstall:
	sudo rm -f $(DESTDIR)$(INSTALL_DIR)/$(TARGET)
	sudo rm -f $(DESTDIR)$(INSTALL_DIR)/smoother_plotter
	sudo rm -rf $(DESTDIR)$(CONFIG_DIR)
	sudo rm -rf $(DESTDIR)$(SHARE_DIR)

clean:
	rm -f $(TARGET)
