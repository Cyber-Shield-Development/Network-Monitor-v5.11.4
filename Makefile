.PHONY: dependencies all clean

CURRENT_DIR=${PWD}

new:
	sudo apt update -y && apt upgrade -y
	sudo apt install make git gcc -y
	git clone https://github.com/vlang/v.git
	cd v
	make
	./v symlink

dependencies:
	sudo apt install -qq net-tools -y

build:
	v shield.v
	@echo Successfull Built ${CURRENT_DIR}