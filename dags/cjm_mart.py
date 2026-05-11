from airflow import DAG 
from airflow.operators.python import PythonOperator 
from datetime import datetime 
from functions import execute_sql_script    

OWNER = "{{ OWNER }}"

with DAG(
          dag_id=f'cjm_mart_dag_{OWNER}',
          start_date = datetime(2026, 5, 10),
          schedule_interval='0 6,12 * * *',
          catchup=False,
          tags=[OWNER],
          default_args={
                    "owner": OWNER
          }
) as dag:
          cjm_customer = PythonOperator( 
                  task_id = 'cjm_customer', 
                  python_callable=execute_sql_script,
                  op_kwargs={'file_path': f'/opt/airflow/dags/{OWNER}/dags/sql/cjm_customer'} 
          )

          cjm_customer_auth = PythonOperator( 
                  task_id = 'cjm_customer_auth', 
                  python_callable=execute_sql_script,
                  op_kwargs={'file_path': f'/opt/airflow/dags/{OWNER}/dags/sql/cjm_customer_auth'} 
          )

          cjm_customer_delete = PythonOperator( 
                  task_id = 'cjm_customer_delete', 
                  python_callable=execute_sql_script,
                  op_kwargs={'file_path': f'/opt/airflow/dags/{OWNER}/dags/sql/cjm_customer_delete'} 
          )

          cjm_purchase = PythonOperator( 
                  task_id = 'cjm_purchase', 
                  python_callable=execute_sql_script,
                  op_kwargs={'file_path': f'/opt/airflow/dags/{OWNER}/dags/sql/cjm_purchase'} 
          )

          cjm_crm_sms = PythonOperator( 
                  task_id = 'cjm_crm_sms', 
                  python_callable=execute_sql_script,
                  op_kwargs={'file_path': f'/opt/airflow/dags/{OWNER}/dags/sql/cjm_crm_sms'} 
          )

          cjm_crm_email = PythonOperator( 
                  task_id = 'cjm_crm_email', 
                  python_callable=execute_sql_script,
                  op_kwargs={'file_path': f'/opt/airflow/dags/{OWNER}/dags/sql/cjm_crm_email'} 
          )

[cjm_customer, cjm_customer_auth, cjm_customer_delete, cjm_purchase, cjm_crm_sms, cjm_crm_email]


