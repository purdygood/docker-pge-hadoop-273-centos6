###############################################################################
# apache hadoop 2.7.3 pseudo cluster
# https://github.com/purdygood/docker-pge-hadoop-273-centos6
# used sequenceiq/hadoop-docker as example
# https://github.com/sequenceiq/hadoop-docker
###############################################################################

from purdygoodengineering/docker-pge-base-centos6:latest
  
  # maintainer
  maintainer matthew purdy <matthew.purdy@purdygoodengineering.com>
  
  env HADOOP_HOME /opt/hadoop
  env HADOOP_PREFIX /opt/hadoop 
  env HADOOP_COMMON_HOME /opt/hadoop 
  env HADOOP_HDFS_HOME /opt/hadoop 
  env HADOOP_MAPRED_HOME /opt/hadoop 
  env HADOOP_YARN_HOME /opt/hadoop 
  env HADOOP_CONF_DIR /opt/hadoop/etc/hadoop 
  env YARN_CONF_DIR $HADOOP_PREFIX/etc/hadoop 
  
  # download native support
  run mkdir -p /tmp/pge/native \
    && wget --quiet --output-document /tmp/pge/native/hadoop-native-64-2.7.0.tar                                           \
            --no-check-certificate --no-cookies http://dl.bintray.com/sequenceiq/sequenceiq-bin/hadoop-native-64-2.7.0.tar \
    && tar -C /tmp/pge/native -xf /tmp/pge/native/hadoop-native-64-2.7.0.tar 
   
  # install hadoop
  run mkdir -p /tmp/pge/hadoop \
    && wget --quiet --output-document /tmp/pge/hadoop/hadoop-2.7.3.tar.gz                                                       \
            --no-check-certificate --no-cookies http://apache.mirrors.hoobly.com/hadoop/common/hadoop-2.7.3/hadoop-2.7.3.tar.gz \
    &&  tar -C /opt -xzf /tmp/pge/hadoop/hadoop-2.7.3.tar.gz                                                                    \
    && chown -R root:root /opt/hadoop-2.7.3                                                                                     \
    && ln -s /opt/hadoop-2.7.3 /opt/hadoop                                                                                      \
    && rm -f /opt/hadoop/bin/*.cmd                                                                                              \
  
  # update /etc/environment 
  run echo ''                                                      >> /etc/environment \
    && echo '# hadoop env vars'                                    >> /etc/environment \
    && echo 'export HADOOP_HOME=/opt/hadoop'                       >> /etc/environment \
    && echo 'export HADOOP_PREFIX=/opt/hadoop'                     >> /etc/environment \
    && echo 'export HADOOP_COMMON_HOME=/opt/hadoop'                >> /etc/environment \
    && echo 'export HADOOP_HDFS_HOME=/opt/hadoop'                  >> /etc/environment \
    && echo 'export HADOOP_MAPRED_HOME=/opt/hadoop'                >> /etc/environment \
    && echo 'export HADOOP_YARN_HOME=/opt/hadoop'                  >> /etc/environment \
    && echo 'export HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop'        >> /etc/environment \
    && echo 'export YARN_CONF_DIR=/opt/hadoop/etc/hadoop'          >> /etc/environment \
    && echo ''                                                     >> /etc/environment \
    && echo 'export PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH' >> /etc/environment \
    && echo ''                                                     >> /etc/environment 
  
  # update bashrc
  run echo ''                                                      >> /root/.bashrc    \
    && echo '# hadoop env vars'                                    >> /root/.bashrc    \
    && echo 'export HADOOP_HOME=/opt/hadoop'                       >> /root/.bashrc    \
    && echo 'export HADOOP_PREFIX=/opt/hadoop'                     >> /root/.bashrc    \
    && echo 'export HADOOP_COMMON_HOME=/opt/hadoop'                >> /root/.bashrc    \
    && echo 'export HADOOP_HDFS_HOME=/opt/hadoop'                  >> /root/.bashrc    \
    && echo 'export HADOOP_MAPRED_HOME=/opt/hadoop'                >> /root/.bashrc    \
    && echo 'export HADOOP_YARN_HOME=/opt/hadoop'                  >> /root/.bashrc    \
    && echo 'export HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop'        >> /root/.bashrc    \
    && echo 'export YARN_CONF_DIR=/opt/hadoop/etc/hadoop'          >> /root/.bashrc    \
    && echo ''                                                     >> /root/.bashrc    \
    && echo 'export PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH' >> /root/.bashrc    \
    && echo ''                                                     >> /root/.bashrc    
    
    run source /root/.bashrc
  
  # remove all pesty windows "shell" scripts
  run rm -f $HADOOP_PREFIX/etc/hadoop/*.cmd \
    && rm -f $HADOOP_PREFIX/sbin/*.cmd

  # update hadoop env
  add hadoop_conf/hadoop-env.sh $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh
  run sed -i "s/<JAVA_HOME>/\/usr\/java\/default/"               $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh \
    && sed -i "s/<HADOOP_HOME>/\/opt\/hadoop/"                   $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh \
    && sed -i "s/<HADOOP_PREFIX>/\/opt\/hadoop/"                 $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh \
    && sed -i "s/<HADOOP_CONF_DIR>/\/opt\/hadoop\/etc\/hadoop/"  $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh
  
  # pseudo distributed add core-site.xml.template $HADOOP_PREFIX/etc/hadoop/core-site.xml.template
  add hadoop_conf/core-site.xml $HADOOP_PREFIX/etc/hadoop/core-site.xml
  add hadoop_conf/hdfs-site.xml $HADOOP_PREFIX/etc/hadoop/hdfs-site.xml
  add hadoop_conf/mapred-site.xml $HADOOP_PREFIX/etc/hadoop/mapred-site.xml
  add hadoop_conf/yarn-site.xml $HADOOP_PREFIX/etc/hadoop/yarn-site.xml
  
  # setup hdfs
  run $HADOOP_PREFIX/bin/hdfs namenode -format
  
  # fix hadoop native
  run rm -rf /opt/hadoop/lib/native       \
    && mv /tmp/pge/native /opt/hadoop/lib \
    && chown -R root:root /opt/hadoop/lib
  
  # update root ssh config
  add ssh_config /root/.ssh/config
  run chmod 600 /root/.ssh/config         \
    && chown root:root /root/.ssh/config
 
  add bootstrap.sh /etc/bootstrap.sh
  run chown root:root /etc/bootstrap.sh   \
    && chmod 700 /etc/bootstrap.sh
  env BOOTSTRAP /etc/bootstrap.sh
  
  # work around the docker.io build error 
  run ls -la /opt/hadoop/etc/hadoop/*-env.sh    \
    && chmod +x /opt/hadoop/etc/hadoop/*-env.sh \
    && ls -la /opt/hadoop/etc/hadoop/*-env.sh
  
  # fix the 254 error code 
  run service sshd stop                                        \
    && sed  -i "/^[^#]*UsePAM/ s/.*/#&/"  /etc/ssh/sshd_config \
    && echo "UsePAM no" >> /etc/ssh/sshd_config                \
    && echo "Port 2122" >> /etc/ssh/sshd_config
 
  # may have to do this in bootstrap 
  run service sshd start                                       \
    && $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh                 \
    && $HADOOP_PREFIX/sbin/start-dfs.sh                        \
    && $HADOOP_PREFIX/bin/hdfs dfs -mkdir -p /user/root
  run service sshd start                                       \
    && $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh                 \
    && $HADOOP_PREFIX/sbin/start-dfs.sh                        \
    && $HADOOP_PREFIX/bin/hdfs dfs -put $HADOOP_PREFIX/etc/hadoop/ input
  
  #cmd ["/etc/bootstrap.sh", "-d"]

  # port on separate lines:
  # 1) hdfs ports
  # 2) mapred ports
  # 3) yarn ports
  # 4) other ports
  expose 50010 50020 50070 50075 50090      \ 
         19888                              \
         8030 8031 8032 8033 8040 8042 8080 \
         49707 2122

