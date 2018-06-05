FROM ruby:2.5-alpine@sha256:26bdf378e71fcb122349d973541862fe27c6acd2b3664fb0fe24dae75fef22b4

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
