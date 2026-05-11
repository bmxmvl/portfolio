from airflow import DAG 
from airflow.operators.python import PythonOperator 
from datetime import datetime 
from functions import execute_sql_script    

OWNER = "{{ OWNER }}"

with DAG(
          dag_id=f'ym_marketing_report_dag_{OWNER}',
          start_date = datetime(2026, 5, 7),
          schedule='0 5 * * *', 
          catchup=False,
          tags=[OWNER],
          default_args={
                    "owner": OWNER
          }
) as dag:
          ym_marketing_report = PythonOperator( 
                  task_id = 'ym_marketing_report', 
                  python_callable=execute_sql_script,
                  op_kwargs={'file_path': f'/opt/airflow/dags/{OWNER}/dags/sql/ym_marketing_report'} 
          )

ym_marketing_report 
