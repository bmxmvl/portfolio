from airflow import DAG 
from airflow.operators.python import PythonOperator 
from datetime import datetime 
from functions import execute_sql_script    

OWNER = "{{ OWNER }}"

with DAG(
          dag_id=f'pl_mart_full_dag_{OWNER}',
          start_date = datetime(2026, 5, 22),
          schedule='0 9 * * 1', 
          catchup=False,
          tags=[OWNER],
          default_args={
                    "owner": OWNER
          }
) as dag:
          pl_mart_full = PythonOperator( 
                  task_id = 'pl_mart_full', 
                  python_callable=execute_sql_script,
                  op_kwargs={'file_path': f'/opt/airflow/dags/{OWNER}/dags/sql/pl_mart_full'} 
          )

pl_mart_full
