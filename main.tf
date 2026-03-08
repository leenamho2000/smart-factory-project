# 1. AWS 프로바이더 설정
provider "aws" {
  region = "ap-northeast-2" # 서울 리전
}

# 2. Bronze 레이어 (원천 데이터: 센서 로그 등)
resource "aws_s3_bucket" "bronze_bucket" {
  bucket = "namho-datalake-bronze-001"
}

# 3. Silver 레이어 (정제 데이터: 데이터 타입 변환 등)
resource "aws_s3_bucket" "silver_bucket" {
  bucket = "namho-datalake-silver-001"
}

# 4. Gold 레이어 (분석 데이터: 수율 계산 등)
resource "aws_s3_bucket" "gold_bucket" {
  bucket = "namho-datalake-gold-001"
}

# AWS Glue Crawler 구축 (IaC)

# 1. Glue가 S3를 읽을 수 있게 해주는 IAM 역할(Role)
resource "aws_iam_role" "glue_role" {
  name = "namho-glue-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = { Service = "glue.amazonaws.com" }
      }
    ]
  })
}

# 2. 역할에 필요한 정책 연결
resource "aws_iam_role_policy_attachment" "glue_s3_policy" {
  role       = aws_iam_role.glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "glue_service_policy" {
  role       = aws_iam_role.glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# 3. Glue 데이터베이스 생성 (논리적 묶음)
resource "aws_glue_catalog_database" "smart_factory_db" {
  name = "smart_factory_db"
}

# 4. Glue 크롤러 생성 (S3를 스캔해서 테이블을 만듦)
resource "aws_glue_crawler" "sensor_crawler" {
  database_name = aws_glue_catalog_database.smart_factory_db.name
  name          = "namho-sensor-crawler"
  role          = aws_iam_role.glue_role.arn

  s3_target {
    path = "s3://${aws_s3_bucket.bronze_bucket.bucket}/"
  }
}

# Glue Job이 사용할 스크립트 파일 위치 정의
resource "aws_s3_object" "etl_script" {
  bucket = aws_s3_bucket.gold_bucket.id # 스크립트 보관용으로 Gold 사용 (또는 별도 버킷)
  key    = "scripts/etl_bronze_to_silver.py"
  source = "etl_bronze_to_silver.py" # 로컬의 파이썬 파일
}

# Glue ETL Job 정의
resource "aws_glue_job" "bronze_to_silver" {
  name     = "namho-etl-bronze-to-silver"
  role_arn = aws_iam_role.glue_role.arn

  command {
    script_location = "s3://${aws_s3_object.etl_script.bucket}/${aws_s3_object.etl_script.key}"
    python_version  = "3"
  }

  default_arguments = {
    "--job-language" = "python"
  }
}

# Silver 레이어용 Glue 크롤러
resource "aws_glue_crawler" "silver_sensor_crawler" {
  database_name = aws_glue_catalog_database.smart_factory_db.name
  name          = "namho-silver-sensor-crawler"
  role          = aws_iam_role.glue_role.arn

  s3_target {
    # 아까 생성된 Parquet 파일이 있는 Silver 버킷 경로
    path = "s3://${aws_s3_bucket.silver_bucket.bucket}/"
  }
}