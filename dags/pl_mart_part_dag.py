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
          dag_id=f'pl_mart_part_dag_{OWNER}',
          start_date = datetime(2026, 5, 22),
          schedule='0 9 * * 2-7', 
          catchup=False,
          tags=[OWNER],
          default_args={
                    "owner": OWNER
          }
) as dag:
          pl_mart_part = PythonOperator( 
                  task_id = 'pl_mart_part', 
                  python_callable=execute_sql_script,
                  op_kwargs={'file_path': f'/opt/airflow/dags/{OWNER}/dags/sql/pl_mart_part'} 
          )

pl_mart_part
