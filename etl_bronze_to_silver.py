import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session

# 1. Bronze 데이터 읽기 (Glue Catalog 사용)
datasource = glueContext.create_dynamic_frame.from_catalog(
    database = "smart_factory_db", 
    table_name = "namho_datalake_bronze_001"
)

# 2. 데이터 변환 (예: 정제 작업)
# 여기서는 간단히 포맷 변환만 수행하지만, 실제로는 여기서 결측치 처리 등을 합니다.

# 3. Silver 레이어(S3)에 Parquet 포맷으로 저장
glueContext.write_dynamic_frame.from_options(
    frame = datasource,
    connection_type = "s3",
    connection_options = {"path": "s3://namho-datalake-silver-001/"},
    format = "parquet"
)

