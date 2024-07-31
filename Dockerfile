FROM apache/airflow:2.9.3
USER root
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
         vim \
  && apt-get autoremove -yqq --purge \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
# 通过 pip 添加包时，需要使用 airflow 用户而不是 root
USER airflow
COPY requirements.txt /
RUN pip install --no-cache-dir -r /requirements.txt
