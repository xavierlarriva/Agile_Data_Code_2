# Setup an environment for running this book's examples

FROM ubuntu
MAINTAINER Russell Jurney, russell.jurney@gmail.com

WORKDIR /root

# Update apt-get and install things
RUN apt-get autoclean
RUN apt-get update && \
    apt-get install -y zip unzip curl bzip2 python-dev build-essential git libssl1.0.0 libssl-dev vim

# Setup Oracle Java8
RUN apt-get install -y software-properties-common debconf-utils && \
    add-apt-repository -y ppa:webupd8team/java && \
    apt-get update && \
    apt-get install -y openjdk-8-jdk
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/

# Download and install Anaconda Python
RUN curl -O https://repo.anaconda.com/archive/Anaconda3-2020.02-Linux-x86_64.sh
RUN bash Anaconda3-2020.02-Linux-x86_64.sh -b -p /root/anaconda
ENV PATH="/root/anaconda/bin:$PATH"

#
# Install git, clone repo, install Python dependencies
#
RUN git clone https://github.com/rjurney/Agile_Data_Code_2
WORKDIR /root/Agile_Data_Code_2
ENV PROJECT_HOME=/Agile_Data_Code_2
ADD requirements.txt .
RUN pip install --upgrade pip && pip install -r requirements.txt 
WORKDIR /root

#
# Install Hadoop: may need to update this link... see http://hadoop.apache.org/releases.html
#
RUN curl -O https://archive.apache.org/dist/hadoop/common/hadoop-2.7.3/hadoop-2.7.3.tar.gz
RUN mkdir -p /root/hadoop && \
    tar -xvf hadoop-2.7.3.tar.gz -C hadoop --strip-components=1
ENV HADOOP_HOME=/root/hadoop
ENV PATH=$PATH:$HADOOP_HOME/bin
ENV HADOOP_CLASSPATH=/root/hadoop/etc/hadoop/:/root/hadoop/share/hadoop/common/lib/*:/root/hadoop/share/hadoop/common/*:/root/hadoop/share/hadoop/hdfs:/root/hadoop/share/hadoop/hdfs/lib/*:/root/hadoop/share/hadoop/hdfs/*:/root/hadoop/share/hadoop/yarn/lib/*:/root/hadoop/share/hadoop/yarn/*:/root/hadoop/share/hadoop/mapreduce/lib/*:/root/hadoop/share/hadoop/mapreduce/*:/root/hadoop/etc/hadoop:/root/hadoop/share/hadoop/common/lib/*:/root/hadoop/share/hadoop/common/*:/root/hadoop/share/hadoop/hdfs:/root/hadoop/share/hadoop/hdfs/lib/*:/root/hadoop/share/hadoop/hdfs/*:/root/hadoop/share/hadoop/yarn/lib/*:/root/hadoop/share/hadoop/yarn/*:/root/hadoop/share/hadoop/mapreduce/lib/*:/root/hadoop/share/hadoop/mapreduce/*:/root/hadoop/contrib/capacity-scheduler/*.jar:/root/hadoop/contrib/capacity-scheduler/*.jar
ENV HADOOP_CONF_DIR=/root/hadoop/etc/hadoop

#
# Install Spark: may need to update this link... see http://spark.apache.org/downloads.html
#
ADD http://mirror.navercorp.com/apache/spark/spark-2.4.6/spark-2.4.6-bin-hadoop2.7.tgz .
RUN mkdir -p /root/spark && \
    tar -xvf spark-2.4.6-bin-hadoop2.7.tgz -C spark --strip-components=1
ENV SPARK_HOME=/root/spark
ENV HADOOP_CONF_DIR=/root/hadoop/etc/hadoop/
ENV SPARK_DIST_CLASSPATH=/root/hadoop/etc/hadoop/:/root/hadoop/share/hadoop/common/lib/*:/root/hadoop/share/hadoop/common/*:/root/hadoop/share/hadoop/hdfs:/root/hadoop/share/hadoop/hdfs/lib/*:/root/hadoop/share/hadoop/hdfs/*:/root/hadoop/share/hadoop/yarn/lib/*:/root/hadoop/share/hadoop/yarn/*:/root/hadoop/share/hadoop/mapreduce/lib/*:/root/hadoop/share/hadoop/mapreduce/*:/root/hadoop/etc/hadoop:/root/hadoop/share/hadoop/common/lib/*:/root/hadoop/share/hadoop/common/*:/root/hadoop/share/hadoop/hdfs:/root/hadoop/share/hadoop/hdfs/lib/*:/root/hadoop/share/hadoop/hdfs/*:/root/hadoop/share/hadoop/yarn/lib/*:/root/hadoop/share/hadoop/yarn/*:/root/hadoop/share/hadoop/mapreduce/lib/*:/root/hadoop/share/hadoop/mapreduce/*:/root/hadoop/contrib/capacity-scheduler/*.jar:/root/hadoop/contrib/capacity-scheduler/*.jar
ENV PATH=$PATH:/root/spark/bin

# Have to set spark.io.compression.codec in Spark local mode, give 8GB RAM
RUN cp /root/spark/conf/spark-defaults.conf.template /root/spark/conf/spark-defaults.conf && \
    echo 'spark.io.compression.codec org.apache.spark.io.SnappyCompressionCodec' >> /root/spark/conf/spark-defaults.conf && \
    echo "spark.driver.memory 8g" >> /root/spark/conf/spark-defaults.conf

# Setup spark-env.sh to use Python 3
RUN echo "PYSPARK_PYTHON=python3" >> /root/spark/conf/spark-env.sh && \
    echo "PYSPARK_DRIVER_PYTHON=python3" >> /root/spark/conf/spark-env.sh

# Setup log4j config to reduce logging output
RUN cp /root/spark/conf/log4j.properties.template /root/spark/conf/log4j.properties && \
    sed -i 's/INFO/ERROR/g' /root/spark/conf/log4j.properties

#
# Install Mongo, Mongo Java driver, and mongo-hadoop and start MongoDB
#
RUN curl https://www.mongodb.org/static/pgp/server-4.2.asc | apt-key add -
RUN echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.2 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-4.2.list
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y mongodb-org && \
    mkdir -p /data/db
# apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6 && \
RUN mongod --fork --logpath /var/log/mongodb.log --config /etc/mongod.conf

# Get the MongoDB Java Driver and put it in Agile_Data_Code_2
ADD https://repo1.maven.org/maven2/org/mongodb/mongo-java-driver/3.11.0/mongo-java-driver-3.11.0.jar /root/Agile_Data_Code_2/lib/

# Install the mongo-hadoop project in the mongo-hadoop directory in the root of our project.
ADD https://github.com/mongodb/mongo-hadoop/archive/r2.0.2.tar.gz .
RUN mkdir -p /root/mongo-hadoop && \
    tar -xvzf r2.0.2.tar.gz -C mongo-hadoop --strip-components=1
WORKDIR /root/mongo-hadoop
RUN /root/mongo-hadoop/gradlew jar
WORKDIR /root
RUN cp /root/mongo-hadoop/spark/build/libs/mongo-hadoop-spark-*.jar /root/Agile_Data_Code_2/lib/ && \
    cp /root/mongo-hadoop/build/libs/mongo-hadoop-*.jar /root/Agile_Data_Code_2/lib/

# Install pymongo_spark
WORKDIR /root/mongo-hadoop/spark/src/main/python
RUN python setup.py install
WORKDIR /root
RUN cp /root/mongo-hadoop/spark/src/main/python/pymongo_spark.py /root/Agile_Data_Code_2/lib/
ENV PYTHONPATH=$PYTHONPATH:/root/Agile_Data_Code_2/lib

# Cleanup mongo-hadoop
RUN rm -rf /root/mongo-hadoop

#
# Install ElasticSearch in the elasticsearch directory in the root of our project, and the Elasticsearch for Hadoop package
#
WORKDIR /root
RUN curl -LO https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.8.0-linux-x86_64.tar.gz
RUN mkdir /root/elasticsearch && \
    tar -xvzf elasticsearch-7.8.0-linux-x86_64.tar.gz -C elasticsearch --strip-components=1
ENV PATH=/root/elasticsearch/bin:$PATH
RUN chown es:es /root
RUN chown -R es:es /root/elasticsearch

# Install Elasticsearch for Hadoop
WORKDIR /root/Agile_Data_Code_2/lib
RUN curl -LO https://repo1.maven.org/maven2/org/elasticsearch/elasticsearch-hadoop/7.8.0/elasticsearch-hadoop-7.8.0.jar
RUN curl -LO https://repo1.maven.org/maven2/org/elasticsearch/elasticsearch-spark-20_2.11/7.8.0/elasticsearch-spark-20_2.11-7.8.0.jar

#
# Install and setup Kafka
#
WORKDIR /root
ADD http://mirror.navercorp.com/apache/kafka/2.5.0/kafka_2.12-2.5.0.tgz .
RUN mkdir -p /root/kafka && \
    tar -xvzf kafka_2.12-2.5.0.tgz -C kafka --strip-components=1

# Run zookeeper (which kafka depends on), then Kafka
RUN sed -i -e 's,#listeners=PLAINTEXT://:9092,listeners=PLAINTEXT://:9092,' /root/kafka/config/server.properties
RUN /root/kafka/bin/zookeeper-server-start.sh -daemon /root/kafka/config/zookeeper.properties && \
    /root/kafka/bin/kafka-server-start.sh -daemon /root/kafka/config/server.properties

# Remove all gz files
RUN rm *gz *sh

#
# Download the data
#
WORKDIR /root/Agile_Data_Code_2/data

# On-time performance records
ADD http://s3.amazonaws.com/agile_data_science/On_Time_On_Time_Performance_2015.csv.gz /root/Agile_Data_Code_2/data/On_Time_On_Time_Performance_2015.csv.gz

# Openflights data
ADD https://raw.githubusercontent.com/jpatokal/openflights/master/data/airports.dat /root/Agile_Data_Code_2/data/airports.dat
ADD https://raw.githubusercontent.com/jpatokal/openflights/master/data/airlines.dat /root/Agile_Data_Code_2/data/airlines.dat
ADD https://raw.githubusercontent.com/jpatokal/openflights/master/data/routes.dat /root/Agile_Data_Code_2/data/routes.dat
ADD https://raw.githubusercontent.com/jpatokal/openflights/master/data/countries.dat /root/Agile_Data_Code_2/data/countries.dat

# FAA data
ADD http://av-info.faa.gov/data/ACRef/tab/aircraft.txt /root/Agile_Data_Code_2/data/aircraft.txt
ADD http://av-info.faa.gov/data/ACRef/tab/ata.txt /root/Agile_Data_Code_2/data/ata.txt
ADD http://av-info.faa.gov/data/ACRef/tab/compt.txt /root/Agile_Data_Code_2/data/compt.txt
ADD http://av-info.faa.gov/data/ACRef/tab/engine.txt /root/Agile_Data_Code_2/data/engine.txt
ADD http://av-info.faa.gov/data/ACRef/tab/prop.txt /root/Agile_Data_Code_2/data/prop.txt

# WBAN Master List
ADD http://www.ncdc.noaa.gov/homr/file/wbanmasterlist.psv.zip /tmp/wbanmasterlist.psv.zip

RUN for i in $(seq -w 1 12); do curl -Lko /tmp/QCLCD2015${i}.zip http://www.ncdc.noaa.gov/orders/qclcd/QCLCD2015${i}.zip && \
    unzip -o /tmp/QCLCD2015${i}.zip && \
    gzip 2015${i}*.txt && \
    rm -f /tmp/QCLCD2015${i}.zip; done

# Back to /root
WORKDIR /root

# Cleanup
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Done!
