from airflow import DAG
from airflow.operators.python import PythonOperator 
from datetime import datetime
from functions import execute_sql_script    

OWNER = "{{ OWNER }}"

with DAG(
          dag_id=f'crm_mart_dag_2_{OWNER}',
          start_date = datetime(2026, 5, 17),
          schedule='0 7 * * *', 
          catchup=False,
          tags=[OWNER],
          default_args={
                    "owner": OWNER
          }
) as dag:
          crm_mart_dag_2 = PythonOperator( 
                  task_id = 'crm_mart_dag_2', 
                  python_callable=execute_sql_script,
                  op_kwargs={'file_path': f'/opt/airflow/dags/{OWNER}/dags/sql/crm_mart'} 
          )

crm_mart_dag_2
