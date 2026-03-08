import pandas as pd
import numpy as np
import boto3
from datetime import datetime
import io

BUCKET_NAME = "namho-datalake-bronze-001" 

def generate_sensor_data(rows=100):
    processes = ['Photo', 'Etch', 'Deposition', 'Diffusion']
    data = {
        'timestamp': [datetime.now().strftime('%Y-%m-%d %H:%M:%S') for _ in range(rows)],
        'equipment_id': [f"EQP-{np.random.randint(100, 105)}" for _ in range(rows)],
        'process_step': [np.random.choice(processes) for _ in range(rows)],
        'temperature': np.random.uniform(20, 100, rows).round(2),
        'pressure': np.random.uniform(1, 10, rows).round(2),
        'status': np.random.choice(['Normal', 'Error'], rows, p=[0.95, 0.05]) # 5% 확률로 에러 발생
    }
    return pd.DataFrame(data)

def upload_to_s3(df, bucket, file_name):
    s3 = boto3.client('s3')
    csv_buffer = io.StringIO()
    df.to_csv(csv_buffer, index=False)
    
    s3.put_object(Bucket=bucket, Key=file_name, Body=csv_buffer.getvalue())
    print(f"✅ 성공: {file_name} 파일이 {bucket}에 업로드되었습니다.")

if __name__ == "__main__":
    # 1. 데이터 생성
    df = generate_sensor_data(100)
    
    # 2. 파일명 결정 (예: sensor_20260308.csv)
    file_name = f"sensor_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv"
    
    # 3. S3 업로드
    upload_to_s3(df, BUCKET_NAME, file_name)