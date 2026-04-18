.PHONY: build clean update

build:
	docker build -t sancho .

clean:
	docker rmi -f sancho

update: clean build
	@echo "Sancho is now running OpenCode v$(shell docker run --rm sancho opencode --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo 'latest')"
