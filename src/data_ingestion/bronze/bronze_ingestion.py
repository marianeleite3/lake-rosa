from pyspark.sql import SparkSession
from pyspark.conf import SparkConf
from delta.pip_utils import configure_spark_with_delta_pip
import findspark

class BronzeIngestion():
    def __init__(self,gcs_project_id, gcs_json_keyfile, warehouse_dir, spark_path):

        findspark.init(spark_path)

        spark_conf = SparkConf()
        spark_conf.set("spark.hadoop.fs.AbstractFileSystem.gs.impl", "com.google.cloud.hadoop.fs.gcs.GoogleHadoopFS")
        spark_conf.set("spark.hadoop.fs.gs.project.id", gcs_project_id)
        spark_conf.set("spark.hadoop.google.cloud.auth.service.account.enable", "true")
        spark_conf.set("spark.hadoop.google.cloud.auth.service.account.json.keyfile", gcs_json_keyfile)
        spark_conf.set("spark.sql.parquet.compression.codec", "gzip")
        spark_conf.set("spark.sql.warehouse.dir", warehouse_dir)
        spark_conf.set("spark.delta.logStore.gs.impl", "io.delta.storage.GCSLogStore")

        spark_conf.set("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension")
        spark_conf.set("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog")
        spark_conf.set("spark.databricks.delta.retentionDurationCheck.enabled", "false")

        spark_conf.set("spark.executor.memory", "70g")
        spark_conf.set("spark.driver.memory", "50g")
        spark_conf.set("spark.memory.offHeap.enabled", "true")
        spark_conf.set("spark.memory.offHeap.size", "16g")

        appName = 'bronze'
        master = 'local[*]'

        spark_builder = SparkSession.builder \
            .appName("Conexao_GCS_Spark") \
            .config(conf=spark_conf)

        self.session = configure_spark_with_delta_pip(spark_builder).getOrCreate()

    def read(self, format, path):

        df = self.session.read.format(format).option("sep", ";").option("inferSchema", "true").option("header", "true").load(path=path)
        return df

    def write(self, df, database_name, table_name, partition_columns=None):
        #df.write.format("delta").option("delta.columnMapping.mode", "name").option("mergeSchema", "true").mode("overwrite").save(path)

        if partition_columns is None :
            df.write.format("delta").saveAsTable(f"{database_name}.{table_name}")
        else:
            df.write.format("delta").partitionBy(*partition_columns).saveAsTable(f"{database_name}.{table_name}")

