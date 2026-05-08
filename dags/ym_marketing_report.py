from airflow import DAG 
from airflow.operators.python import PythonOperator 
from datetime import datetime 
from functions import execute_sql_script    

OWNER = "{{ max_b }}" #обеспечивает уникальность дагов по ученикам для деплоя

with DAG(
          dag_id=f'ym_marketing_report_dag_{OWNER}', #меняет название дага до _dag
          start_date = datetime(2026, 5, 7),
          schedule='0 8 * * *', #меняем расписание запуска дага
          catchup=False,
          tags=[max_b],
          default_args={
                    "owner": max_b
          }
) as dag:
# создаем задачу, в которой вызываем python функцию execute_sql_script и передаем в нее название sql скрипта
          ym_marketing_report = PythonOperator( #меняем название задачи
                  task_id = 'ym_marketing_report', #меняем название задачи
                  python_callable=execute_sql_script,
                  op_kwargs={'file_path': f'/opt/airflow/dags/{OWNER}/dags/sql/ym_marketing_report'} #меняем название sql скрипта
          )

ym_marketing_report #меняем название задачи
