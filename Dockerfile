FROM ruby:3.3-alpine@sha256:447495d87e72344ac35f14afd4bebd635eaafcaf3f147ebb72a15fa555b8584e as build

WORKDIR /app
COPY bin /app/bin
COPY lib /app/lib
COPY spec /app/spec
COPY README.md /app/
COPY CHANGES.md /app/
COPY LICENSE.md /app/
COPY stackup.gemspec /app/
RUN gem build stackup.gemspec

FROM ruby:3.3-alpine@sha256:447495d87e72344ac35f14afd4bebd635eaafcaf3f147ebb72a15fa555b8584e

MAINTAINER https://github.com/realestate-com-au/stackup

COPY --from=build /app/stackup-*.gem /tmp/

RUN apk --no-cache add diffutils \
 && gem install --no-document /tmp/stackup-*.gem \
 && rm -f /tmp/stackup-*.gem /usr/local/bundle/gems/stackup-*/*.md \
 && rm -rf /usr/local/bundle/gems/stackup-*/spec

WORKDIR /cwd
ENTRYPOINT ["stackup"]
