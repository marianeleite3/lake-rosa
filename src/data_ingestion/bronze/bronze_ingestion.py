from pyspark.sql import *
from pyspark.sql import DataFrame
from pyspark.sql.types import StructType
from pyspark.sql.session import SparkSession


class BronzeIngestion():
    def __init__(self):

        MASTER_URI = "spark://spark:7077"
        self.session = SparkSession.builder \
            .master("local") \
            .appName("TestWriteDeltaLake") \
            .config("spark.jars.packages", "io.delta:delta-core_2.12:2.2.0") \
            .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension") \
            .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog").getOrCreate()

    def read(self, format, path) -> DataFrame:
        df = self.session.read.format(format).option("sep", ";").option("inferSchema", "true").option("header", "true").load(path=path)
        return df

    def write(self, df, path):
        df.write.format("delta").option("delta.columnMapping.mode", "name").option("mergeSchema", "true").mode("overwrite").save(path)
