FROM ruby:2.6-alpine@sha256:65c14862929f88ba54cebd63177d9437c46dda2e7c47484fb1d3178825dd1585

MAINTAINER https://github.com/realestate-com-au/stackup

RUN apk --no-cache add diffutils

WORKDIR /app

COPY bin /app/bin
COPY lib /app/lib
COPY spec /app/spec
COPY README.md /app/
COPY CHANGES.md /app/
COPY LICENSE.md /app/
COPY stackup.gemspec /app/

RUN gem build stackup.gemspec
RUN gem install stackup-*.gem

WORKDIR /cwd

ENTRYPOINT ["stackup"]
