
all: deploy

build:
	@npm install --unsafe-perm

deploy: build
	bash scripts/deploy.sh