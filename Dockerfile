ARG ERIC_ENM_SLES_APACHE2_IMAGE_NAME=eric-enm-sles-apache2
ARG ERIC_ENM_SLES_APACHE2_IMAGE_REPO=armdocker.rnd.ericsson.se/proj-enm
ARG ERIC_ENM_SLES_APACHE2_IMAGE_TAG=1.59.0-33

FROM ${ERIC_ENM_SLES_APACHE2_IMAGE_REPO}/${ERIC_ENM_SLES_APACHE2_IMAGE_NAME}:${ERIC_ENM_SLES_APACHE2_IMAGE_TAG}

ARG BUILD_DATE=unspecified
ARG IMAGE_BUILD_VERSION=unspecified
ARG GIT_COMMIT=unspecified
ARG ISO_VERSION=unspecified
ARG RSTATE=unspecified
ARG SGUSER=277540

LABEL \
com.ericsson.product-number="CXC Placeholder" \
com.ericsson.product-revision=$RSTATE \
enm_iso_version=$ISO_VERSION \
org.label-schema.name="ENM sps UI SideCar" \
org.label-schema.build-date=$BUILD_DATE \
org.label-schema.vcs-ref=$GIT_COMMIT \
org.label-schema.vendor="Ericsson" \
org.label-schema.version=$IMAGE_BUILD_VERSION \
org.label-schema.schema-version="1.0.0-rc1"

RUN zypper install -y ERICpkimanagerui_CXP9032047 && \
    zypper clean -a

ENV CREDM_CONTROLLER_MNG="TRUE"
ENV PROXY_PASS_RULES="pki-manager,key-access-provider-service,pki-web-cli,credential-manager-service,pki-core,credential-manager-web-cli-handler"
ENV DISABLE_CREDM_RETRY=true
ENV POD_IP="sps"

COPY image_content/createCertificatesLinks.sh /ericsson/3pp/jboss/bin/pre-start/createCertificatesLinks.sh

COPY image_content/updateCertificatesLinks.sh /usr/lib/ocf/resource.d/updateCertificatesLinks.sh
RUN /bin/chmod 775 /usr/lib/ocf/resource.d/updateCertificatesLinks.sh

RUN /bin/chown jboss_user:jboss /ericsson/3pp/jboss/bin/pre-start/createCertificatesLinks.sh
RUN /bin/chmod 775 /ericsson/3pp/jboss/bin/pre-start/createCertificatesLinks.sh

RUN if rpm -e --nodeps ERICcredentialmanagercli_CXP9031389 ; then echo 'Removed ERICcredentialmanagercli_CXP9031389 from eric-enmsg-sps-web-service' ; else echo 'No ERICcredentialmanagercli_CXP9031389 installed inside eric-enmsg-sps-web-service' ; fi
RUN /bin/mkdir -p /ericsson/credm/data/certs && \
    /bin/chown -R jboss_user:jboss /ericsson/credm/data/certs && \
    /bin/chmod -R 775 /ericsson/credm/data/certs 

RUN  echo "$SGUSER:x:$SGUSER:$SGUSER:An Identity for websps:/nonexistent:/bin/false" >>/etc/passwd && \
     echo "$SGUSER:!::0:::::" >>/etc/shadow

EXPOSE 8084 8444

USER $SGUSER