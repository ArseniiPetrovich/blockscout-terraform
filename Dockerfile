FROM bitwalker/alpine-elixir-phoenix:1.9.0 AS phx-builder

ENV HOME=/opt/app/ \
    DYNO=$HOSTNAME \
    MIX_ENV=prod \
    LANG="en_US.UTF-8" \
    LC_COLLATE="en_US.UTF-8" \
    LC_CTYPE="en_US.UTF-8" \
    LC_MESSAGES="en_US.UTF-8" \
    LC_MONETARY="en_US.UTF-8" \
    LC_NUMERIC="en_US.UTF-8" \
    LC_TIME="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8"

ADD .env.tmp /tmp/

RUN apk --no-cache --update add alpine-sdk gmp-dev automake libtool inotify-tools autoconf python git

RUN source /tmp/.env.tmp && rm -R /opt/app && cd /tmp && git clone -b $BLOCKSCOUT_BRANCH $BLOCKSCOUT_REPO /opt/app

WORKDIR /opt/app

RUN source /tmp/.env.tmp && mix do deps.get, deps.compile

ARG COIN
RUN if [ "$COIN" != "" ]; then sed -i s/"POA"/"${COIN}"/g apps/block_scout_web/priv/gettext/en/LC_MESSAGES/default.po; fi

RUN source /tmp/.env.tmp && mix compile phx.digest

RUN source /tmp/.env.tmp && \
    cd apps/block_scout_web/assets/ && \
    npm install && \
    npm run deploy && \
    cd -

##### Final Image

FROM bitwalker/alpine-elixir:1.9.0

ENV HOME=/opt/app/ \
    MIX_ENV=prod \
    PORT=4000

COPY --from=phx-builder /opt/app /opt/app

WORKDIR ${HOME}

EXPOSE ${PORT}

CMD ["mix", "phx.server"]
