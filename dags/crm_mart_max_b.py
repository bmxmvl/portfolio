from airflow import DAG
from datetime import datetime

OWNER = "{{ OWNER }}"

with DAG(
    dag_id=f'crm_mart_{OWNER}',
    start_date=datetime(2026, 5, 16),
    schedule=None,
    catchup=False,
    tags=[OWNER],
    default_args={"owner": OWNER}
) as dag:
    pass
