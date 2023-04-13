# build the WAR with the JDK
FROM eclipse/ubuntu_jdk8 AS build
USER root
WORKDIR /opt
ADD https://altushost-swe.dl.sourceforge.net/project/symmetricds/symmetricds/symmetricds-3.14/symmetric-server-3.14.3.zip symmetric-server-3.14.3.zip
RUN /usr/bin/unzip symmetric-server-3.14.3.zip
WORKDIR /opt/symmetric-server-3.14.3
# This should be part of the ECS service
COPY engines engines 
COPY conf/symmetric-server.properties conf/symmetric-server.properties
CMD [ "./bin/sym" ]
