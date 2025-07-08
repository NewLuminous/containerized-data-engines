# Stage 1: Base image and ARG/ENV setup
FROM openjdk:11-jdk-slim AS base

# -- Build-time Arguments with defaults --
# These are set by the 'docker build --build-arg' command.
ARG SPARK_VERSION_ARG=3.3.3
ARG SPARK_DISTRIBUTION_ARG=hadoop3
ARG SCALA_VERSION_ARG=2.12
ARG PYTHON_VERSION_ARG=3.9
ARG HADOOP_USER_NAME_ARG=spark
ARG APP_USER_UID=1000
ARG APP_USER_GID=1000

# Spark libraries & Connectors
ARG MSSQL_JDBC_VERSION_ARG=12.6.1.jre11
ARG MYSQL_JDBC_VERSION_ARG=8.0.33
ARG ORACLE_DRIVER_SUITE_VERSION_ARG=23.6.0.24.10
ARG POSTGRES_JDBC_VERSION_ARG=42.7.3
ARG KAFKA_CLIENTS_VERSION_ARG=2.8.1
ARG ICEBERG_VERSION_ARG=1.4.2
ARG COMMONS_POOL_VERSION_ARG=2.11.1

# -- Runtime Environment Variables --
# Set from ARGs to make them available inside the container at runtime
ENV SPARK_VERSION=${SPARK_VERSION_ARG}
ENV SPARK_DISTRIBUTION=${SPARK_DISTRIBUTION_ARG}
ENV SCALA_VERSION=${SCALA_VERSION_ARG}
ENV PYTHON_VERSION=${PYTHON_VERSION_ARG}
ENV JAVA_HOME=/usr/local/openjdk-11
ENV SPARK_HOME=/opt/spark
ENV PATH=${SPARK_HOME}/bin:${SPARK_HOME}/sbin:${JAVA_HOME}/bin:${PATH}
ENV PYSPARK_PYTHON=python${PYTHON_VERSION_ARG}
ENV PYSPARK_DRIVER_PYTHON=python${PYTHON_VERSION_ARG}
ENV HADOOP_USER_NAME=${HADOOP_USER_NAME_ARG}
# Directory where YARN configuration .xml files will be mounted
ENV SPARK_CONF_DIR=${SPARK_HOME}/conf
ENV HADOOP_CONF_DIR=${SPARK_CONF_DIR}

# Set DEBIAN_FRONTEND to noninteractive to avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Set locale environment variables. These are crucial for Python's encoding handling.
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Stage 2: Install dependencies and Spark
FROM base AS builder

# System dependencies
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        bash \
        tini \
        curl \
        gnupg \
        "python${PYTHON_VERSION_ARG}" \
        "python${PYTHON_VERSION_ARG}-dev" \
        "python${PYTHON_VERSION_ARG}-distutils" \
        locales \
        wget \
    && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=${LANG} && \
    # Verify python standard lib (especially encodings) is populated in builder
    echo "Listing /usr/lib/python${PYTHON_VERSION_ARG}/encodings/ in builder:" && \
    ls -l /usr/lib/python${PYTHON_VERSION_ARG}/encodings/ && \
    wget https://bootstrap.pypa.io/get-pip.py && \
    "python${PYTHON_VERSION_ARG}" get-pip.py && \
    rm get-pip.py && \
    "python${PYTHON_VERSION_ARG}" -m pip --version && \
    # Symlink for convenience if needed
    ln -sf /usr/bin/python${PYTHON_VERSION_ARG} /usr/bin/python3 && \
    ln -sf /usr/bin/python${PYTHON_VERSION_ARG} /usr/bin/python && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install PySpark (matching the Spark version)
RUN "python${PYTHON_VERSION_ARG}" -m pip install --no-cache-dir pyspark=="${SPARK_VERSION_ARG}" wheel

# Download and install Spark
RUN curl -sL "https://archive.apache.org/dist/spark/spark-${SPARK_VERSION_ARG}/spark-${SPARK_VERSION_ARG}-bin-${SPARK_DISTRIBUTION_ARG}.tgz" \
        | tar -xz -C /opt && \
    mv "/opt/spark-${SPARK_VERSION_ARG}-bin-${SPARK_DISTRIBUTION_ARG}" "${SPARK_HOME}" && \
    mkdir -p "${SPARK_CONF_DIR}" && \
    sh -c ' \
        echo "log4j.rootCategory=INFO, console" > "${SPARK_HOME}/conf/log4j.properties.template" && \
        echo "log4j.appender.console=org.apache.log4j.ConsoleAppender" >> "${SPARK_HOME}/conf/log4j.properties.template" && \
        echo "log4j.appender.console.target=System.err" >> "${SPARK_HOME}/conf/log4j.properties.template" && \
        echo "log4j.appender.console.layout=org.apache.log4j.PatternLayout" >> "${SPARK_HOME}/conf/log4j.properties.template" && \
        echo "log4j.appender.console.layout.ConversionPattern=%d{yy/MM/dd HH:mm:ss} %p %c{1}: %m%n" >> "${SPARK_HOME}/conf/log4j.properties.template" \
    '

# Download dependent JARs
RUN MAVEN_CENTRAL_URL="https://repo1.maven.org/maven2" && \
    MYSQL_CONNECTOR_J_JAR="mysql-connector-j-${MYSQL_JDBC_VERSION_ARG}.jar" && \
    curl -fSL -o "${SPARK_HOME}/jars/${MYSQL_CONNECTOR_J_JAR}" \
        "${MAVEN_CENTRAL_URL}/com/mysql/mysql-connector-j/${MYSQL_JDBC_VERSION_ARG}/${MYSQL_CONNECTOR_J_JAR}" && \
    \
    MSSQL_JDBC_JAR="mssql-jdbc-${MSSQL_JDBC_VERSION_ARG}.jar" && \
    curl -fSL -o "${SPARK_HOME}/jars/${MSSQL_JDBC_JAR}" \
        "${MAVEN_CENTRAL_URL}/com/microsoft/sqlserver/mssql-jdbc/${MSSQL_JDBC_VERSION_ARG}/${MSSQL_JDBC_JAR}" && \
    \
    ORACLE_JDBC_JAR="ojdbc11-${ORACLE_DRIVER_SUITE_VERSION_ARG}.jar" && \
    curl -fSL -o "${SPARK_HOME}/jars/${ORACLE_JDBC_JAR}" \
        "${MAVEN_CENTRAL_URL}/com/oracle/database/jdbc/ojdbc11/${ORACLE_DRIVER_SUITE_VERSION_ARG}/${ORACLE_JDBC_JAR}" && \
    # Oracle XML DB (for XMLType support, often needed with ojdbc)
    XMLPARSERV2_JAR="xmlparserv2-${ORACLE_DRIVER_SUITE_VERSION_ARG}.jar" && \
    curl -fSL -o "${SPARK_HOME}/jars/${XMLPARSERV2_JAR}" \
        "${MAVEN_CENTRAL_URL}/com/oracle/database/xml/xmlparserv2/${ORACLE_DRIVER_SUITE_VERSION_ARG}/${XMLPARSERV2_JAR}" && \
    XDB_JAR="xdb-${ORACLE_DRIVER_SUITE_VERSION_ARG}.jar" && \
    curl -fSL -o "${SPARK_HOME}/jars/${XDB_JAR}" \
        "${MAVEN_CENTRAL_URL}/com/oracle/database/xml/xdb/${ORACLE_DRIVER_SUITE_VERSION_ARG}/${XDB_JAR}" && \
    \
    POSTGRES_JDBC_JAR="postgresql-${POSTGRES_JDBC_VERSION_ARG}.jar" && \
    curl -fSL -o "${SPARK_HOME}/jars/${POSTGRES_JDBC_JAR}" \
        "${MAVEN_CENTRAL_URL}/org/postgresql/postgresql/${POSTGRES_JDBC_VERSION_ARG}/${POSTGRES_JDBC_JAR}" && \
    \
    # Spark Kafka Connector
    SPARK_KAFKA_JAR="spark-sql-kafka-0-10_${SCALA_VERSION}-${SPARK_VERSION_ARG}.jar" && \
    curl -fSL -o "${SPARK_HOME}/jars/${SPARK_KAFKA_JAR}" \
        "${MAVEN_CENTRAL_URL}/org/apache/spark/spark-sql-kafka-0-10_${SCALA_VERSION}/${SPARK_VERSION_ARG}/${SPARK_KAFKA_JAR}" && \
    SPARK_KAFKA_TOKEN_PROVIDER_JAR="spark-token-provider-kafka-0-10_${SCALA_VERSION}-${SPARK_VERSION_ARG}.jar" && \
    curl -fSL -o "${SPARK_HOME}/jars/${SPARK_KAFKA_TOKEN_PROVIDER_JAR}" \
        "${MAVEN_CENTRAL_URL}/org/apache/spark/spark-token-provider-kafka-0-10_${SCALA_VERSION}/${SPARK_VERSION_ARG}/${SPARK_KAFKA_TOKEN_PROVIDER_JAR}" && \
    COMMONS_POOL_JAR="commons-pool2-${COMMONS_POOL_VERSION_ARG}.jar" && \
    curl -fSL -o "${SPARK_HOME}/jars/${COMMONS_POOL_JAR}" \
        "${MAVEN_CENTRAL_URL}/org/apache/commons/commons-pool2/${COMMONS_POOL_VERSION_ARG}/${COMMONS_POOL_JAR}" && \
    KAFKA_CLIENTS_JAR="kafka-clients-${KAFKA_CLIENTS_VERSION_ARG}.jar" && \
    curl -fSL -o "${SPARK_HOME}/jars/${KAFKA_CLIENTS_JAR}" \
        "${MAVEN_CENTRAL_URL}/org/apache/kafka/kafka-clients/${KAFKA_CLIENTS_VERSION_ARG}/${KAFKA_CLIENTS_JAR}" && \
    \
    SPARK_MAJOR_MINOR_VERSION=$(echo "${SPARK_VERSION_ARG}" | cut -d. -f1-2) && \
    ICEBERG_SPARK_RUNTIME_JAR="iceberg-spark-runtime-${SPARK_MAJOR_MINOR_VERSION}_${SCALA_VERSION}-${ICEBERG_VERSION_ARG}.jar" && \
    ICEBERG_SPARK_EXTENSIONS_JAR="iceberg-spark-extensions-${SPARK_MAJOR_MINOR_VERSION}_${SCALA_VERSION}-${ICEBERG_VERSION_ARG}.jar" && \
    echo "Downloading ${ICEBERG_SPARK_RUNTIME_JAR} for Spark ${SPARK_MAJOR_MINOR_VERSION} and Scala ${SCALA_VERSION}" && \
    curl -fSL -o "${SPARK_HOME}/jars/${ICEBERG_SPARK_RUNTIME_JAR}" \
        "${MAVEN_CENTRAL_URL}/org/apache/iceberg/iceberg-spark-runtime-${SPARK_MAJOR_MINOR_VERSION}_${SCALA_VERSION}/${ICEBERG_VERSION_ARG}/${ICEBERG_SPARK_RUNTIME_JAR}" && \
    echo "Downloading ${ICEBERG_SPARK_EXTENSIONS_JAR} for Spark ${SPARK_MAJOR_MINOR_VERSION} and Scala ${SCALA_VERSION}" && \
    curl -fSL -o "${SPARK_HOME}/jars/${ICEBERG_SPARK_EXTENSIONS_JAR}" \
        "${MAVEN_CENTRAL_URL}/org/apache/iceberg/iceberg-spark-extensions-${SPARK_MAJOR_MINOR_VERSION}_${SCALA_VERSION}/${ICEBERG_VERSION_ARG}/${ICEBERG_SPARK_EXTENSIONS_JAR}"

# Stage 3: User setup and final image
FROM base AS final

# Install runtime OS dependencies needed by copied binaries (Python, Spark scripts)
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        procps \
        libexpat1 \
        libsqlite3-0 \
        locales \
    && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=${LANG} && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy installed Spark and Python dependencies from builder stage
COPY --from=builder ${SPARK_HOME} ${SPARK_HOME}
COPY --from=builder /usr/local/lib/python${PYTHON_VERSION_ARG}/dist-packages /usr/local/lib/python${PYTHON_VERSION_ARG}/dist-packages
COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /usr/lib/python${PYTHON_VERSION_ARG} /usr/lib/python${PYTHON_VERSION_ARG}
COPY --from=builder /usr/bin/python* /usr/bin/
COPY --from=builder /usr/bin/tini /usr/bin/tini

# Verify Python installation in final image and ensure symlinks are correct
RUN echo "Verifying Python standard library in final image:" && \
    ls -l /usr/lib/python${PYTHON_VERSION}/encodings/ && \
    echo "Ensuring Python symlinks:" && \
    if [ ! -L /usr/bin/python3 ]; then ln -sf /usr/bin/python${PYTHON_VERSION} /usr/bin/python3; else echo "python3 symlink ok"; fi && \
    if [ ! -L /usr/bin/python ]; then ln -sf /usr/bin/python${PYTHON_VERSION} /usr/bin/python; else echo "python symlink ok"; fi && \
    chmod +x /usr/bin/tini $(find /usr/local/bin -type f) $(find /usr/bin -name 'python*' -type f)

# Create user and group
RUN groupadd -r spark --gid=${APP_USER_GID} && \
    useradd -r -g spark --uid=${APP_USER_UID} -m -d /home/spark -s /bin/bash spark && \
    mkdir -p "${SPARK_HOME}" && chown -R spark:spark "${SPARK_HOME}" && \
    mkdir -p "${SPARK_CONF_DIR}" && chown -R spark:spark "${SPARK_CONF_DIR}" && \
    chown -R spark:spark /home/spark

USER spark
WORKDIR /home/spark

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["bash"]