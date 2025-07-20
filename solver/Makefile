CXX := g++
CXXFLAGS := -std=c++11 -O3 -Wall

TARGET := brent_solver
INSTALL_DIR := /usr/local/bin
CONFIG_DIR := /etc/solver
SCRIPT_DIR := /usr/local/share/solver

SRC := src/brent_solver.cpp
SCRIPT := scripts/run_solver.sh
CONFIG := data/config_solver.json

all: $(TARGET)

$(TARGET): $(SRC)
	$(CXX) $(CXXFLAGS) -o $@ $^

install:
	# Бинарник
	sudo install -d $(DESTDIR)$(INSTALL_DIR)
	sudo install -m 755 $(TARGET) $(DESTDIR)$(INSTALL_DIR)
	
	# Скрипт
	sudo install -d $(DESTDIR)$(SCRIPT_DIR)
	sudo install -m 755 $(SCRIPT) $(DESTDIR)$(SCRIPT_DIR)
	sudo ln -sf $(SCRIPT_DIR)/$(notdir $(SCRIPT)) $(DESTDIR)$(INSTALL_DIR)/run_solver
	
	# Конфиг
	sudo install -d $(DESTDIR)$(CONFIG_DIR)
	sudo install -m 644 $(CONFIG) $(DESTDIR)$(CONFIG_DIR)/config_solver.json

uninstall:
	sudo rm -f $(DESTDIR)$(INSTALL_DIR)/$(TARGET)
	sudo rm -f $(DESTDIR)$(INSTALL_DIR)/run_solver
	sudo rm -rf $(DESTDIR)$(CONFIG_DIR)
	sudo rm -rf $(DESTDIR)$(SCRIPT_DIR)

clean:
	rm -f $(TARGET)
