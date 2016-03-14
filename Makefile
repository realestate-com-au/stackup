REPOSITORY = realestate-com-au/stackup

VERSION := $(shell TZ=Australia/Melbourne date +'%Y%m%d%H%M')

default: build

bootstrap:
	docker-compose run --rm dev bundle install

test: bootstrap
	docker-compose run --rm dev bundle exec rake spec

build_gem: bootstrap
	docker-compose run --rm dev bundle exec rake build

build_docker_image: build_gem
	docker build -t $(REPOSITORY):latest .

build: build_gem build_docker_image

no_local_changes:
	git diff HEAD --exit-code

release_gem: bootstrap
	docker-compose run --rm dev bundle exec rake release

release_docker_image:
	docker tag $(REPOSITORY):latest $(REPOSITORY):$(VERSION)
	docker push $(REPOSITORY):$(VERSION)
	docker push $(REPOSITORY):latest

release: test build release_gem release_docker_image
