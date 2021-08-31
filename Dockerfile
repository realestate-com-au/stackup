FROM ruby:2.6-alpine@sha256:fff44cacf0eee17e86eb66a8047d7a14e851e009f4c9e2bf0bd787b7bb324893 as build

WORKDIR /app
COPY bin /app/bin
COPY lib /app/lib
COPY spec /app/spec
COPY README.md /app/
COPY CHANGES.md /app/
COPY LICENSE.md /app/
COPY stackup.gemspec /app/
RUN gem build stackup.gemspec

FROM ruby:2.6-alpine@sha256:fff44cacf0eee17e86eb66a8047d7a14e851e009f4c9e2bf0bd787b7bb324893

MAINTAINER https://github.com/realestate-com-au/stackup

COPY --from=build /app/stackup-*.gem /tmp/

RUN apk --no-cache add diffutils \
 && gem install --no-document /tmp/stackup-*.gem \
 && rm -f /tmp/stackup-*.gem /usr/local/bundle/gems/stackup-*/*.md \
 && rm -rf /usr/local/bundle/gems/stackup-*/spec

WORKDIR /cwd
ENTRYPOINT ["stackup"]
