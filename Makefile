.PHONY: dependencies all clean
CURRENT_DIR=${PWD}

new:
	sudo apt update -y && apt upgrade -y
	sudo apt install git gcc -y
	cd ~/; git clone https://github.com/vlang/v.git
	cd ~/v; sudo make
	~/v/v symlink

dependencies:
	sudo apt install -qq net-tools -y
	sudo apt install -qq speedtest-cli -y
	sudo apt install -qq nload -y
	@echo Dependencies installed....

build:
	v cs.v -o shield -cflags -g3 -O0 -Wall -Wextra -pedantic -prod
	@echo Successfull Built ${CURRENT_DIR}/shield

bins:
	v cs.v -prod -o shield -cflags -g3 -O0 -Wall -Wextra -pedantic
	v cs.v -arch arm64 -o bins/shield_arm64 -prod -cflags -o3 -s
	v cs.v -arch amd64 -o bins/shield_amd64 -prod -cflags -o3 -s
	mkdir bins
	mkdir bins/assets
	mkdir bins/assets/dumps
	mkdir bins/assets/themes
	cp assets/protection.shield bins/assets/protection.shield
	cp -r assets/themes/builtin bins/assets/themes/builtin
	mv shield_arm32 bins/; mv shield_arm64 bins/; mv shield_amd64 bins/
	@echo Bins created in ${CURRENT_DIR}/bins/

clean:
	rm -rf src
	rm -rf cs.v
	@echo Cleaned up!