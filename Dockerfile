# Copyright (c) 2016-present Sonatype, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM       ubuntu:16.04
MAINTAINER Jiang Rensheng <13841495@qq.com>

#### set environment to fix term not set issues when building docker image ####
ENV DEBIAN_FRONTEND noninteractive

LABEL vendor=Sonatype \
  com.sonatype.license="Apache License, Version 2.0" \
  com.sonatype.name="Nexus Repository Manager base image"

ARG NEXUS_VERSION=3.3.1-01
ARG NEXUS_DOWNLOAD_URL=https://download.sonatype.com/nexus/3/nexus-${NEXUS_VERSION}-unix.tar.gz

RUN apt-get update \
  && apt-get install -y curl tar \
  && apt-get clean

# configure java runtime
ENV JAVA_HOME=/opt/java \
  JAVA_VERSION_MAJOR=8 \
  JAVA_VERSION_MINOR=131 \
  JAVA_VERSION_BUILD=11 \
  JAVA_DOWNLOAD_HASH=d54c1d3a095b4ff2b6607d096fa80163

# configure nexus runtime
ENV SONATYPE_DIR=/opt/sonatype
ENV NEXUS_HOME=${SONATYPE_DIR}/nexus \
  NEXUS_DATA=/nexus-data \
  NEXUS_CONTEXT='' \
  SONATYPE_WORK=${SONATYPE_DIR}/sonatype-work

# install Oracle JRE
RUN mkdir -p /opt \
  && curl --fail --silent --location --retry 3 \
  --header "Cookie: oraclelicense=accept-securebackup-cookie; " \
  http://download.oracle.com/otn-pub/java/jdk/${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-b${JAVA_VERSION_BUILD}/${JAVA_DOWNLOAD_HASH}/server-jre-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.tar.gz \
  | gunzip \
  | tar -x -C /opt \
  && ln -s /opt/jdk1.${JAVA_VERSION_MAJOR}.0_${JAVA_VERSION_MINOR} ${JAVA_HOME}

# install nexus
RUN mkdir -p ${NEXUS_HOME} \
  && curl --fail --silent --location --retry 3 \
    ${NEXUS_DOWNLOAD_URL} \
  | gunzip \
  | tar x -C ${NEXUS_HOME} --strip-components=1 nexus-${NEXUS_VERSION} \
  && chown -R root:root ${NEXUS_HOME}

# configure nexus
RUN sed \
    -e '/^nexus-context/ s:$:${NEXUS_CONTEXT}:' \
    -i ${NEXUS_HOME}/etc/nexus-default.properties \
  && sed \
    -e '/^-Xms/d' \
    -e '/^-Xmx/d' \
    -i ${NEXUS_HOME}/bin/nexus.vmoptions

#### Add User Nexus ####
RUN useradd -r -u 200 -m -c "nexus role account" -d ${NEXUS_DATA} -s /bin/false nexus \
  && mkdir -p ${NEXUS_DATA}/etc ${NEXUS_DATA}/log ${NEXUS_DATA}/tmp ${SONATYPE_WORK} \
  && ln -s ${NEXUS_DATA} ${SONATYPE_WORK}/nexus3 \
  && chown -R nexus:nexus ${NEXUS_DATA}

#### Configure Nexus for SSL ####
ENV JETTY_ETC="${NEXUS_HOME}/etc/jetty"
ENV JETTY_HTTPS_XML="${JETTY_ETC}/jetty-https.xml"
ENV SSL_CONFIG_DIR="${NEXUS_HOME}/etc/ssl"
ENV NEXUS_PROPERTIES="${NEXUS_HOME}/etc/nexus-default.properties"

RUN sed -i "s|<Set name=\"KeyStorePath\">.*</Set>|<Set name=\"KeyStorePath\">${SSL_CONFIG_DIR}/keystore.jks</Set>|g" ${JETTY_HTTPS_XML}
RUN sed -i "s|<Set name=\"KeyStorePassword\">.*</Set>|<Set name=\"KeyStorePassword\">jrsjrs</Set>|g" ${JETTY_HTTPS_XML}
RUN sed -i "s|<Set name=\"KeyManagerPassword\">.*</Set>|<Set name=\"KeyManagerPassword\">jrsjrs</Set>|g" ${JETTY_HTTPS_XML}
RUN sed -i "s|<Set name=\"TrustStorePath\">.*</Set>|<Set name=\"TrustStorePath\">${SSL_CONFIG_DIR}/keystore.jks</Set>|g" ${JETTY_HTTPS_XML}
RUN sed -i "s|<Set name=\"TrustStorePassword\">.*</Set>|<Set name=\"TrustStorePassword\">jrsjrs</Set>|g" ${JETTY_HTTPS_XML}

RUN sed -i -e '/nexus-args=/ s/=.*/=${JETTY_ETC}\/jetty.xml,${JETTY_ETC}\/jetty-requestlog.xml,${JETTY_ETC}\/jetty-http.xml,${JETTY_ETC}\/jetty-https.xml,${JETTY_ETC}\/jetty-http-redirect-to-https.xml/' ${NEXUS_PROPERTIES}

RUN echo "application-port-ssl=8443" >> ${NEXUS_PROPERTIES}

RUN ${JAVA_HOME}/bin/keytool -genkeypair \
    -keystore ${SSL_CONFIG_DIR}/keystore.jks \
    -storepass jrsjrs \
    -keypass jrsjrs \
    -alias jetty \
    -keyalg RSA \
    -keysize 2048 \
    -validity 5000 \
    -dname "CN=*.deepsecs.com, OU=Example, O=Sonatype, L=Unspecified, ST=Unspecified, C=US" \
    -ext "SAN=DNS:deepsecs.com" \
    -ext "BC=ca:true"

#### configure nexus runtime env ####
RUN sed \
    -e "s|karaf.home=.|karaf.home=${NEXUS_HOME}|g" \
    -e "s|karaf.base=.|karaf.base=${NEXUS_HOME}|g" \
    -e "s|karaf.etc=etc|karaf.etc=${NEXUS_HOME}/etc|g" \
    -e "s|java.util.logging.config.file=etc|java.util.logging.config.file=${NEXUS_HOME}/etc|g" \
    -e "s|karaf.data=data|karaf.data=${NEXUS_DATA}|g" \
    -e "s|java.io.tmpdir=data/tmp|java.io.tmpdir=${NEXUS_DATA}/tmp|g" \
    -i ${NEXUS_HOME}/bin/nexus.vmoptions

EXPOSE 8081 5000 5001 8443

VOLUME ${NEXUS_DATA}

USER nexus
WORKDIR ${NEXUS_HOME}

ENV INSTALL4J_ADD_VM_PARAMS="-Xms1200m -Xmx1200m"

CMD ["bin/nexus", "run"]
