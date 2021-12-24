FROM ruby:3.0-alpine@sha256:9afcc885895358e84929c19ea53cb62ecc50daf93dcbd45de469f2e668d96e9a as build

WORKDIR /app
COPY bin /app/bin
COPY lib /app/lib
COPY spec /app/spec
COPY README.md /app/
COPY CHANGES.md /app/
COPY LICENSE.md /app/
COPY stackup.gemspec /app/
RUN gem build stackup.gemspec

FROM ruby:3.0-alpine@sha256:9afcc885895358e84929c19ea53cb62ecc50daf93dcbd45de469f2e668d96e9a

MAINTAINER https://github.com/realestate-com-au/stackup

COPY --from=build /app/stackup-*.gem /tmp/

RUN apk --no-cache add diffutils \
 && gem install --no-document /tmp/stackup-*.gem \
 && rm -f /tmp/stackup-*.gem /usr/local/bundle/gems/stackup-*/*.md \
 && rm -rf /usr/local/bundle/gems/stackup-*/spec

WORKDIR /cwd
ENTRYPOINT ["stackup"]
