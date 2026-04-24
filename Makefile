.PHONY: build build-with-cache clean update install

build:
	docker build --no-cache -t sancho .

build-with-cache:
	docker build -t sancho .

clean:
	docker rmi -f sancho

update: clean build
	@echo "Sancho is now running OpenCode v$(shell docker run --rm sancho opencode --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo 'latest')"

install:
	@if [ ! -f /usr/local/bin/sancho ]; then \
		make build; \
		sudo ln -sf $(PWD)/run.sh /usr/local/bin/sancho; \
	else \
		echo "sancho link already exists"; \
	fi
