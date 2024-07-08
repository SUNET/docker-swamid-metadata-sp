VERSION:=latest
NAME=swamid/metadata-sp

all: build push
build:
	docker build --no-cache=true -t $(NAME):$(VERSION) .
	docker tag $(NAME):$(VERSION) docker.sunet.se/$(NAME):$(VERSION)
update:
	docker build -t $(NAME):$(VERSION) .
	docker tag $(NAME):$(VERSION) docker.sunet.se/$(NAME):$(VERSION)
push:
	docker push docker.sunet.se/$(NAME):$(VERSION)

stable:
	docker pull docker.sunet.se/$(NAME):$(VERSION)
	docker tag docker.sunet.se/$(NAME):$(VERSION) docker.sunet.se/$(NAME):stable
	docker push docker.sunet.se/$(NAME):stable

testing:
	make VERSION=testing
