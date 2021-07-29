FROM alpine

ENV PATH="/container/scripts:${PATH}"

RUN apk add --no-cache python3 \
                       py3-pip \
                       git \
\
&& pip install --upgrade pip \
&& pip install fauxmo \
\
&& mkdir /etc/fauxmo/ \
\
&& git clone https://github.com/n8henrie/fauxmo-plugins /fauxmo-plugins \
\
&& apk del --no-cache git

COPY . /container/

HEALTHCHECK CMD ["docker-healthcheck.sh"]
ENTRYPOINT ["entrypoint.sh"]

CMD [ "fauxmo" ]
