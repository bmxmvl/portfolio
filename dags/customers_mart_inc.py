from airflow import DAG 
from airflow.operators.python import PythonOperator 
from datetime import datetime 
from pathlib import Path
import sys

dag_folder = Path(__file__).parent
if str(dag_folder) not in sys.path:
    sys.path.insert(0, str(dag_folder))
          
from functions import execute_sql_script

OWNER = "{{ OWNER }}"

with DAG(
    dag_id=f'customers_mart_inc_dag_{OWNER}',
    start_date=datetime(2026, 5, 15),
    schedule='0 * * * *',
    catchup=False,
    tags=[OWNER],
    default_args={
        "owner": OWNER
    }
) as dag:
    customers_mart_inc = PythonOperator(
        task_id='customers_mart_inc',
        python_callable=execute_sql_script,
        op_kwargs={
            'file_path': f'/opt/airflow/dags/{OWNER}/dags/sql/customers_mart_inc'
        }
    )

    customers_mart_inc
