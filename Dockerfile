FROM avishnoi/odl-ovsdb-cluster-node-image:2.0.0

MAINTAINER Flavio Fernandes <flavio@flaviof.com>
ENV REFRESHED_AT 2017-01-27

RUN \
  apt-get update && \
  apt-get -y upgrade && \
  ln -s /home/avishnoi/clustering/ovsdb/be/karaf/target/assembly /root/ && \
  ln -s /home/avishnoi/clustering/ovsdb/be/scripts /root/ && \
  rm -rf /root/.m2 /home/avishnoi/clustering/ovsdb/be/karaf/target/assembly

ADD assembly.tar.gz /home/avishnoi/clustering/ovsdb/be/karaf/target/

RUN \
  echo 'ovsdb.l3.fwd.enabled=yes' >> /home/avishnoi/clustering/ovsdb/be/karaf/target/assembly/etc/custom.properties && \
  /bin//sed -i "/^featuresBoot=/ s/$/,odl-ovsdb-openstack/" /home/avishnoi/clustering/ovsdb/be/karaf/target/assembly/etc/org.apache.karaf.features.cfg && \
  rm -rf /home/avishnoi/clustering/ovsdb/be/karaf/target/assembly/{data,journal,snapshots} && \
  echo ok

# Set environment variables.
ENV HOME /root

# Define working directory.
WORKDIR /root

# Define default command.
CMD ["bash"]
