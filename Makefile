.PHONY: dependencies all clean

CURRENT_DIR=${PWD}

new:
	sudo apt update -y && apt upgrade -y
	sudo apt install make git gcc -y
	cd ~/; git clone https://github.com/vlang/v.git
	cd ~/v
	make
	./v symlink

dependencies:
	sudo apt install -qq net-tools -y
	sudo apt install -qq speedtest-cli -y
	sudo apt install -qq nload -y
	@echo Dependencies installed....

build:
	v cs.v -o shield -prod
	@echo Successfull Built ${CURRENT_DIR}/shield

bins:
	v cs.v -o shield -prod
	v cs.v -arch arm32 -o shield_arm32 -prod -cflags -o3 -s
	v cs.v -arch arm64 -o shield_arm64 -prod -cflags -o3 -s
	v cs.v -arch amd64 -o shield_amd64 -prod -cflags -o3 -s
	mv shield_arm32 bin/; mv shield_arm64 bin/; mv shield_amd64 bin/
	@echo Bins created in ${CURRENT_DIR}/bins/