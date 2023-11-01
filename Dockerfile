FROM python:3.10.12-slim-buster

ENV PYTHONHASHSEED=1234

#RUN apt-get update  > /dev/null  && \
#    apt-get install openjdk-8-jdk-headless -qq > /dev/null\  && \
#    wget -q https://downloads.apache.org/spark/spark-3.4.1/spark-3.4.1-bin-hadoop3.tgz  && \
#    tar xf spark-3.4.1-bin-hadoop3.tgz  && \
#    wget -q https://storage.googleapis.com/hadoop-lib/gcs/gcs-connector-hadoop3-latest.jar

RUN apt-get update && apt-get install -y wget

RUN apt-get update && \
    apt-get install -y openjdk-11-jdk-headless -qq && \
    wget -q https://downloads.apache.org/spark/spark-3.4.1/spark-3.4.1-bin-hadoop3.tgz && \
    tar xf spark-3.4.1-bin-hadoop3.tgz && \
    wget -q https://storage.googleapis.com/hadoop-lib/gcs/gcs-connector-hadoop3-latest.jar

ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64\
    SPARK_HOME=/spark-3.4.1-bin-hadoop3\
    SPARK_VERSION=3.4.1

RUN mv gcs-connector-hadoop3-latest.jar $SPARK_HOME/jars/

RUN pip install --upgrade pip

COPY ./requirements.txt ./requirements.txt
RUN pip3 install -r ./requirements.txt

RUN mkdir ${HOME}/src
WORKDIR ${HOME}/src
COPY src .

ENV PYTHONPATH "${PYTHONPATH}:${HOME}/src"

CMD ["python3", "./data_ingestion/entrypoint.py"]
