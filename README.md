# PySpark YARN Client Docker Image

This image provides a PySpark environment configured to submit jobs to a remote YARN cluster and interact with HDFS, including Iceberg support.

## Prerequisites

1.  **Docker:** Ensure Docker is installed and running.
2.  **Hadoop/YARN Configuration:**
    *   Create a local directory named `conf`.
    *   Copy your Hadoop/YARN cluster configuration files (`core-site.xml`, `hdfs-site.xml`, `yarn-site.xml`, `hive-site.xml` if using Hive Metastore for Iceberg) into this `conf` directory. These files must be configured to connect to your remote cluster.
3.  **PySpark Scripts:**
    *   Create a local directory named `scripts`.
    *   Place your PySpark (`.py`) scripts in this directory.

## Build the Image

This image uses build arguments that can be customized via a `.env` file and a `build.sh` script.

1.  **Create `.env` (Optional - for custom versions):**
    ```env
    # .env
    SPARK_VERSION=3.3.3
    SPARK_DISTRIBUTION=hadoop3
    PYTHON_VERSION=3.9
    SCALA_VERSION=2.12 # For Iceberg compatibility
    ICEBERG_VERSION=1.4.2
    # User for HDFS/YARN access (if not Kerberized & different from container user)
    CDP_HDFS_USER=your_hdfs_user
    ```
2.  **Run `build.sh`:**
    ```bash
    chmod +x build.sh
    ./build.sh
    ```
    This will build the image, named `newluminous/pyspark` by default.

## Run the Container

Execute the following command from the same directory where your `conf` and `scripts` folders are located:

```bash
docker run -it --rm \
    --network="host" \
    -v ./conf:/opt/spark/conf \
    -v ./scripts:/home/spark/scripts \
    -e HADOOP_USER_NAME=admin \
    newluminous/pyspark
```

**Explanation of `docker run` options:**
*   `-it`: Interactive TTY.
*   `--rm`: Remove container on exit.
*   `--network="host"`: Uses the host's network stack. Simplifies connectivity to YARN/HDFS if they are accessible from the host, but has security implications. Adjust if needed.
*   `-v ./conf:/opt/spark/conf`: Mounts your Hadoop/YARN configuration files.
*   `-v ./scripts:/home/spark/scripts`: Mounts your PySpark scripts.

**Inside the Container:**

You will be logged in as the `spark` user.

*   **Interactive PySpark Shell (YARN client mode):**
    ```bash
    pyspark --master yarn --deploy-mode client
    ```
*   **Submit a PySpark Script (YARN cluster mode):**
    ```bash
    spark-submit --master yarn --deploy-mode cluster /home/spark/scripts/your_script.py
    ```

**HDFS Permissions Note:**
If you encounter HDFS permission errors, ensure the `CDP_HDFS_USER` in your `.env` file (which sets `HADOOP_USER_NAME` in the container) is a user with appropriate permissions on your HDFS cluster. If your cluster is Kerberized, you'll need to adapt the image and runtime for Kerberos authentication (keytab, krb5.conf).
