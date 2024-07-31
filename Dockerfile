FROM apache/airflow:2.9.3
USER root
COPY requirements.txt /
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
         vim \
  && apt-get autoremove -yqq --purge \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
  
RUN pip install --no-cache-dir "apache-airflow==2.9.3" -r /requirements.txt
USER airflow
