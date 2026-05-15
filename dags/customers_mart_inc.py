from airflow import DAG 
from airflow.operators.python import PythonOperator 
from datetime import datetime 
from functions import execute_sql_script    

OWNER = "{{ OWNER }}"

with DAG(
          dag_id=f'customers_mart_inc_dag_{OWNER}',
          start_date = datetime(2026, 5, 15),
          schedule='0 * * * *', 
          catchup=False,
          tags=[OWNER],
          default_args={
                    "owner": OWNER
          }
) as dag:
          ym_marketing_report = PythonOperator( 
                  task_id = 'customers_mart_inc', 
                  python_callable=execute_sql_script,
                  op_kwargs={'file_path': f'/opt/airflow/dags/{OWNER}/dags/sql/customers_mart_inc'} 
          )

customers_mart_inc 
