FROM ruby:2.6-alpine@sha256:44dcc51eb5dd33ea70abf2450e06a29093b30b880280b6b09fb58dd65b416b3b

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
