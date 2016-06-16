FROM ruby:2.3-alpine

MAINTAINER https://github.com/realestate-com-au/stackup

RUN apk --no-cache add diffutils

WORKDIR /app

COPY bin /app/bin
COPY lib /app/lib
COPY spec /app/spec
COPY README.md /app/
COPY CHANGES.md /app/
COPY stackup.gemspec /app/

RUN gem build stackup.gemspec
RUN gem install stackup-*.gem

WORKDIR /cwd

ENTRYPOINT ["stackup"]
