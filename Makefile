.PHONY: dependencies all clean

CURRENT_DIR=${PWD}

new:
	sudo apt update -y && apt upgrade -y
	sudo apt install make git gcc -y
	cd ~/; git clone https://github.com/vlang/v.git
	cd v
	make
	./v symlink

dependencies:
	sudo apt install -qq net-tools -y
	sudo apt install -qq speedtest-cli -y

build:
	v cs.v -o shield
	@echo Successfull Built ${CURRENT_DIR}/shield

quick:
	v cs.v -o shield
	rm -rf src; rm -rf cs.v; rm -rf v.mod
	cd ..; mv shield /home/ubuntu/
	@echo Update pushed to user 