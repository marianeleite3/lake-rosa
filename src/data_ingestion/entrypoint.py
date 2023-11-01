import os
from data_ingestion.bronze.bronze_ingestion import BronzeIngestion
from data_ingestion.delta_lake_tools.catalog_loader import DeltaLakeDatabaseGsCreator
from google.cloud import storage
from data_ingestion.delta_lake_tools.parquet_to_delta import ParquetToDelta


# id do projeto
# project_id = 'teak-ellipse-317015'
project_id = 'teak-ellipse-317015'

# id do bucket dentro do projeto
bucket_id = 'observatorio-oncologia'

# nome da pasta do projeto
project_folder_name = 'monitor'

dev_lake_name = "lake-rosa-dev"
lake_zone = "bronze"
# database_name = "cancer_data"

script_dir = os.path.dirname(os.path.abspath(__file__))

json_filename_str = 'teak-ellipse-317015-5490da87b4a1.json'

# Construct the full path to the JSON key file
json_filename = os.path.join(script_dir, json_filename_str)


warehouse_dir = f"gs://{bucket_id}/{dev_lake_name}/"
# warehouse_dir = f"/content/{dev_lake_name}/"

storage_client = storage.Client.from_service_account_json(json_filename)

spark_path = os.getenv('SPARK_HOME')

database_location = f'{dev_lake_name}/{lake_zone}'

spark = BronzeIngestion(gcs_project_id = project_folder_name,
                          gcs_json_keyfile= json_filename,
                          warehouse_dir=warehouse_dir,
                          spark_path=spark_path)
spark_session = spark.session


def write_bronze_ibge_data():
    db_creator_bronze_ibge = DeltaLakeDatabaseGsCreator(
        spark_session=spark_session,
        storage_client=storage_client,
        gs_bucket_id=bucket_id,
        database_location=database_location,
        database_name="ibge")
    db_creator_bronze_ibge.create_database(use_db_folder_path=True)
    df = spark.read('csv','gs://observatorio-oncologia/monitor/ibge_data/ibge_pop_sexo_grupos_idade_municipios.csv')
    # return df
    spark.write(df,database_name ='ibge',table_name='ibge_cidades')


def write_bronze_sia_data():
    db_creator_bronze_sia = DeltaLakeDatabaseGsCreator(
        spark_session=spark_session,
        storage_client=storage_client,
        gs_bucket_id=bucket_id,
        database_location=database_location,
        database_name="sia_data")
    db_creator_bronze_sia.create_database(use_db_folder_path=True)

    parquet_to_delta_sia_pa = ParquetToDelta(spark)
    parquet_path = f'gs://{bucket_id}/{project_folder_name}/SP/*/*/SIA/PA/*.parquet.gzip'
    database_name = "sia_data"  # Defina o nome do banco de dados
    table_name = "pa"  # Defina o nome da tabela Delta

    unique_columns = []  # Deixe a lista de colunas únicas vazia
    partition_columns = ["_filename", ]  # Defina as colunas de partição

    # Configurar o nome do banco de dados
    parquet_to_delta_sia_pa.set_database_name(database_name)

    # Configurar o nome da tabela
    parquet_to_delta_sia_pa.set_table_name(table_name)

    # Realizar a ingestão inicial
    parquet_to_delta_sia_pa.set_partition_columns(partition_columns)
    parquet_to_delta_sia_pa.ingest_initial_parquet_to_delta(parquet_path)


# write_bronze_ibge_data()
write_bronze_sia_data()

