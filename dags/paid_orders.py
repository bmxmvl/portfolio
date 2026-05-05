from airflow import DAG 
from airflow.operators.python import PythonOperator 
from datetime import datetime 
from functions import execute_sql_script    

OWNER = "{{ OWNER }}" #обеспечивает уникальность дагов по ученикам для деплоя

with DAG(
          dag_id=f'paid_orders_dag_{OWNER}', #меняет название дага до _dag
          start_date = datetime(2026, 5, 5),
          schedule='0 6 * * *', #меняем расписание запуска дага
          catchup=False,
          tags=[OWNER],
          default_args={
                    "owner": OWNER
          }
) as dag:
# создаем задачу, в которой вызываем python функцию execute_sql_script и передаем в нее название sql скрипта
          paid_orders = PythonOperator( #меняем название задачи
                  task_id = 'paid_orders', #меняем название задачи
                  python_callable=execute_sql_script,
                  op_kwargs={'file_path': f'/opt/airflow/dags/{OWNER}/dags/sql/paid_orders'} #меняем название sql скрипта
          )

paid_orders #меняем название задачи
