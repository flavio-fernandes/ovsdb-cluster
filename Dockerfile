FROM lwieske/java-8:jdk-8u66

MAINTAINER Flavio Fernandes <flavio@flaviof.com>

EXCLUDE /root/anaconda-ks.cfg

# Set environment variables.
ENV REFRESHED_AT 2017-01-26
ENV HOME /root
ENV ODL_PATH /root

# See info on grabbing assembly.tar.gz in blog page
# http://www.flaviof.com/blog/work/how-to-odl-in-docker.html

ADD assembly.tar.gz $ODL_PATH/
ADD configuration_initial $ODL_PATH/assembly/configuration/initial
ADD scripts $ODL_PATH/

RUN \
  echo 'ovsdb.l3.fwd.enabled=yes' >> $ODL_PATH/assembly/etc/custom.properties && \
  /bin/sed -i "/^featuresBoot=/ s/$/,odl-ovsdb-openstack/" $ODL_PATH/assembly/etc/org.apache.karaf.features.cfg && \
  ln -s $ODL_PATH/assembly/data/log/karaf.log && \
  ln -s $ODL_PATH/scripts/env.sh && \
  rm -rf $ODL_PATH/assembly/{data,journal,snapshots} && \
  echo ok

# Define working directory.
WORKDIR /root

# Define default command.
CMD ["bash"]
