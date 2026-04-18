.PHONY: build clean update

build:
	docker build -t sancho .

clean:
	docker rmi -f sancho

update: clean build
