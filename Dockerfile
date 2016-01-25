FROM lwieske/java-8:jdk-8u66

MAINTAINER Flavio Fernandes <flavio@flaviof.com>

# Set environment variables.
ENV REFRESHED_AT 2017-01-26
ENV HOME /root
ENV ODL_PATH /root

VOLUME [ "/root/.m2" ]

# See info on grabbing assembly.tar.gz in blog page
# http://www.flaviof.com/blog/work/how-to-odl-in-docker.html

ADD assembly.tar.gz $ODL_PATH/
ADD configuration_initial $ODL_PATH/assembly/configuration/initial
ADD scripts/_configure-node.sh $ODL_PATH/scripts/configure-node.sh

RUN \
  echo 'ovsdb.l3.fwd.enabled=yes' >> $ODL_PATH/assembly/etc/custom.properties && \
  /bin/sed -i "/^featuresBoot=/ s/$/,odl-ovsdb-openstack/" $ODL_PATH/assembly/etc/org.apache.karaf.features.cfg && \
  ln -s $ODL_PATH/assembly/data/log $ODL_PATH && \
  chmod +x $ODL_PATH/scripts/configure-node.sh && \
  rm -rf $ODL_PATH/assembly/{data,journal,snapshots} && \
  rm -f /root/anaconda-ks.cfg && \
  echo ok

# Define working directory.
WORKDIR /root

# Define default command.
CMD ["bash"]
