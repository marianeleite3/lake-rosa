from pyspark.sql import SparkSession
from pyspark.conf import SparkConf
from delta.pip_utils import configure_spark_with_delta_pip
import findspark

class SparkSession():
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

        appName = 'bronze'
        master = 'local[*]'

        spark_builder = SparkSession.builder \
            .appName("Conexao_GCS_Spark") \
            .config(conf=spark_conf)

        self.session = configure_spark_with_delta_pip(spark_builder).getOrCreate()
