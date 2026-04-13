from airflow import DAG 
from airflow.operators.python import PythonOperator 
from datetime import datetime 
from functions import execute_sql_script    

OWNER = "{{ OWNER }}" #обеспечивает уникальность дагов по ученикам для деплоя

with DAG(
          dag_id=f'example_core_customer_dag_{OWNER}', #меняет название дага до _dag
          start_date = datetime(2024, 4, 21),
          schedule='0 7 * * *', #меняем расписание запуска дага
          catchup=False,
          tags=[OWNER],
          default_args={
                    "owner": OWNER
          }
) as dag:
# создаем задачу, в которой вызываем python функцию execute_sql_script и передаем в нее название sql скрипта
          core_customer = PythonOperator( #меняем название задачи
                  task_id = 'core_customer', #меняем название задачи
                  python_callable=execute_sql_script,
                  op_kwargs={'file_path': f'/opt/airflow/dags/{OWNER}/dags/sql/customers'} #меняем название sql скрипта
          )

core_customer #меняем название задачи
