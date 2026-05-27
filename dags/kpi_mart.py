from airflow import DAG 
from airflow.operators.python import PythonOperator 
from datetime import datetime 
from functions import execute_sql_script    

OWNER = "{{ OWNER }}"

with DAG(
          dag_id=f'kpi_mart_dag_{OWNER}',
          start_date = datetime(2026, 5, 27),
          schedule='0 6 * * *', 
          catchup=False,
          tags=[OWNER],
          default_args={
                    "owner": OWNER
          }
) as dag:
          kpi_mart = PythonOperator( 
                  task_id = 'kpi_mart', 
                  python_callable=execute_sql_script,
                  op_kwargs={'file_path': f'/opt/airflow/dags/{OWNER}/dags/sql/kpi_mart'} 
          )

kpi_mart
