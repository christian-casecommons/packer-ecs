FROM alpine
MAINTAINER Pema Geyleg <pema@casecommons.org>
LABEL application=packer
ARG packer_version

RUN echo "http://nl.alpinelinux.org/alpine/edge/testing/" >> /etc/apk/repositories && \
    apk add --no-cache --update curl bash jq confd py2-pip && \
    pip install awscli && \
    curl -L https://releases.hashicorp.com/packer/${packer_version}/packer_${packer_version}_linux_amd64.zip -o /packer.zip && \
    unzip /packer.zip -d /usr/bin && \
    rm /packer.zip

COPY src/etc/confd /etc/confd
COPY src /packer
WORKDIR /packer

ENTRYPOINT ["/packer/entrypoint.sh"]
CMD ["packer", "build", "packer.json"]