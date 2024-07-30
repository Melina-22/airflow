### 许可证

- 根据一个或多个贡献者许可协议授权给Apache软件基金会（ADF）。有关版权所有权的详细信息，请参见此工作的NOTICE文件。
- ASF根据Apache许可证2.0版（the License）许可此文件；除非符合许可证，否则你不能使用此文件。你可以在以下地址获得许可证：http://www.apache.org/licenses/LICENSE-2.0
- 除非适用法律要求或书面同意，否则根据许可证分发的软件是按“原样”分发的，没有任何形式的明示或暗示担保。参见许可证以了解特定语言管理权限和限制。

### [服务定义](https://airflow.apache.org/docs/apache-airflow/stable/howto/docker-compose/index.html)

- **airflow-scheduler** - 调度程序监视所有任务和 DAB，然后在任务实例的依赖项完成后触发任务实例
- **airflow-webserver** - Web服务器，可在 http://localhost:8080 访问
- **airflow-worker** - 执行调度程序给定任务的工作程序
- **airflow-triggerer** - 触发器为可延迟任务运行事件循环
- **airflow-init** - 初始化服务
- **airflow-cli** - 用于在 Docker 容器中运行 Apache Airflow 的命令行界面（CLI）
- **postgres** - 数据库
- **redis** - 将消息从调度程序转发到工作程序的代理 https://redis.io/
- **flower** - 可选项，用于监测环境的应用程序，可通过 http://localhost:5555 访问。 可以通过添加--profile flower选项来启用flower，例如 `docker compose--profile flower-up`，或者通过在命令行上显式指定它，例如 `docker-compose-up flower`

### CeleryExecutor与Redis和PostgreSQL的基本Airflow集群配置。

| 环境变量                       | 描述                                                         | 默认值                 |
| ------------------------------ | ------------------------------------------------------------ | ---------------------- |
| `AIRFLOW_IMAGE_NAME`           | 用于运行Airflow的Docker镜像名称                              | `apache/airflow:2.9.3` |
| `AIRFLOW_UID`                  | Airflow容器中的用户ID                                        | `50000`                |
| `AIRFLOW_PROJ_DIR`             | 所有文件将被挂载到的基本路径                                 | `.`                    |
| `_AIRFLOW_WWW_USER_USERNAME`   | 管理员帐户的用户名                                           | `airflow`              |
| `_AIRFLOW_WWW_USER_PASSWORD`   | 管理员帐户的密码                                             | `airflow`              |
| `_PIP_ADDITIONAL_REQUIREMENTS` | 启动所有容器时添加的额外PIP要求，仅用于快速检查或测试，每次启动服务时都会重新安装这些额外的 Python 包，会导致启动时间变长。更好的方法是构建一个自定义镜像或扩展官方镜像，详见 https://airflow.apache.org/docs/docker-stack/build.html. | `''`                   |

### 容器中的目录

- 计划将服务部署到 `/opt/appdata/airflow/` 中，容器中的目录映射到 data 目录下

/opt/data/airflow/data/
├── dags                  #-- DAG 文件存放位置
├── logs                   #-- 包含来自任务执行和调度程序的日志
├── config               #-- 可以添加自定义日志解析器或添加airflow_local_settings.py以配置集群策略 
├── plugins             #-- 自定义插件存放位置
└── postgres          #-- posegresql 中的data目录映射位置

### 部署

```shell
# 进入安装目录
cd /opt/appdata/airflow

# 创建文件夹
mkdir -p ./data/dags ./data/logs ./data/plugins ./data/config ./data/postgres

# 将当前用户id写入 .env 环境变量文件中
echo -e "AIRFLOW_UID=$(id -u)" > .env

# 初始化数据库
docker compose up airflow-init

# 运行 airflow
docker compose up



# 清理环境：官方提供的 docker-compose 环境是一个“快速入门”环境。它不是为在生产中使用而设计的，它有许多警告 - 其中之一是从任何问题中恢复的最佳方法是清理它并从头开始重新启动。

docker compose down --volumes --remove-orphans
```

### 交互

- 通过运行 [CLI 命令](https://airflow.apache.org/docs/apache-airflow/stable/howto/usage-cli.html)

  ```shell
  # Linux 或 Mac OS，可以下载可选的脚本，以便使用更简单的命令运行命令
  curl -LfO 'https://airflow.apache.org/docs/apache-airflow/2.9.3/airflow.sh'
  chmod +x airflow.sh
  
  docker compose run airflow-worker airflow info # 运行 airflow info
  ./airflow.sh info # 使用脚本运行 airflow info
  
  ./airflow.sh bash # 使用 bash 作为参数在容器中进入交互式 bash shell
  ./airflow.sh python # 使用 Python 进入 Python 容器
  
  docker-compose run --rm airflow-cli airflow dags list # 列出所有 DAGs
  ./airflow.sh airflow dags lis # 列出所有 DAGs
  ```

- 通过使用 [web界面](https://airflow.apache.org/docs/apache-airflow/stable/ui.html) http://localhost:8080

- 使用 [REST API](https://airflow.apache.org/docs/apache-airflow/stable/stable-rest-api-ref.html)

  ```shell
  # 使用 curl 命令发送请求以检索池列表
  ENDPOINT_URL="http://localhost:8080/"
  curl -X GET  \
      --user "airflow:airflow" \
      "${ENDPOINT_URL}/api/v1/pools"
  ```

### 构建镜像

- 在 Dockerfile 中每个 `RUN` 指令都会创建一个新的镜像层，这会增加最终镜像的大小。为了优化 Docker 镜像的大小和构建性能，通常会将多个命令合并到一个 `RUN` 指令中，并清除缓存和不必要的文件。

- 在 Airflow 映像中安装 vim

```dockerfile
# --no-install-recommends 只安装指定的软件包及其依赖项，不安装推荐的软件包
# pt-get autoremove -yqq --purge 自动删除不再需要的包及其依赖项，并清理所有配置文件
# apt-get clean 清理 apt-get 缓存的包文件，释放空间
# rm -rf /var/lib/apt/lists/* 删除 apt-get 的包列表文件，以进一步减少镜像的大小

FROM apache/airflow:2.9.3
USER root
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
         vim \
  && apt-get autoremove -yqq --purge \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
USER airflow
```

- 通过 `pip` 添加包时，需要使用 `airflow` 用户而不是 `root`

```dockerfile
# --no-cache-dir 标志指示 pip 不要缓存包文件，以减少镜像的大小

FROM apache/airflow:2.9.3
COPY requirements.txt /
RUN pip install --no-cache-dir "apache-airflow==${AIRFLOW_VERSION}" -r /requirements.txt
```

requirements.txt

```python

```

### 网络

```yaml
airflow-worker:
    extra_hosts:
      - "host.docker.internal:host-gateway"
```

