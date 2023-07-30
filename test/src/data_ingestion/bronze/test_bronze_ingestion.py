from src.data_ingestion.bronze.bronze_ingestion import BronzeIngestion
import pytest
import os
from pyspark.sql.session import SparkSession

source_path = os.path.abspath(os.path.join(os.path.dirname(__file__)))


class TestBronzeIngestion:

    @pytest.fixture
    def bronze(self):
        return BronzeIngestion()

    def test_read_write(self, bronze):
        """

        :type bronze: object
        """
        format_file = "csv"
        files_path = source_path + "/data/ibge_cidades.csv"
        df = bronze.read(format=format_file, path=files_path)

        output_path = source_path + "/data/output"
        bronze.write(df=df, path=output_path)

        assert df.count() == 5570
