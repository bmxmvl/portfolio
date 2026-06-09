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
          dag_id=f'ltv_mart_dag_{OWNER}',
          start_date = datetime(2026, 5, 19),
          schedule='0 7 * * 1', 
          catchup=False,
          tags=[OWNER],
          default_args={
                    "owner": OWNER
          }
) as dag:
          ltv_mart = PythonOperator( 
                  task_id = 'ltv_mart', 
                  python_callable=execute_sql_script,
                  op_kwargs={'file_path': f'/opt/airflow/dags/{OWNER}/dags/sql/ltv_mart'} 
          )

ltv_mart 
