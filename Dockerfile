FROM alpine

ENV PATH="/container/scripts:${PATH}"

RUN apk add --no-cache python3 \
                       py3-pip \
                       git \
                       curl \
\
&& pip install --break-system-packages --upgrade pip \
&& pip install --break-system-packages fauxmo \
\
&& mkdir /etc/fauxmo/ \
\
&& git clone https://github.com/n8henrie/fauxmo-plugins /fauxmo-plugins \
&& rm -rf /fauxmo-plugins/.git \
\
&& apk del --no-cache git

COPY . /container/

HEALTHCHECK CMD ["docker-healthcheck.sh"]
ENTRYPOINT ["entrypoint.sh"]

CMD [ "fauxmo" ]
