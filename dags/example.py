#импорт всех нужных в вашем даге библиотек
from airflow import DAG 
from airflow.operators.python import PythonOperator 
from datetime import datetime

#до самого определения DAG можно определить python функции, логику которых можно вызывать в рамках задач
def example():
          "функция просто выводит слово hi world"
          print('hi world')

def summarize():
          "функция суммирует 5+2 и выводит 7"
          print(5+2)

OWNER = "{{ OWNER }}" 

#определение DAG с его параметрами
with DAG(
          dag_id=f'example_dag_{OWNER}', #название dag
          start_date = datetime(2024, 4, 21), #дата с которой dag будет поставлен на расписание, обычно ставят дату в прошлом
          schedule='0 6 * * *', #расписание запуска dag
          catchup=False, #параметр, показывающий нужно или нет запускать даг в промежуток времени между start_date и текущей датой
          tags=[OWNER],
          default_args={
                    "owner": OWNER
          }
) as dag:
#определение списка задач для дага
          print_hi = PythonOperator(
                  task_id = 'print_hi_airflow',
                  python_callable=example
          )

          summarize_example = PythonOperator(
                  task_id = 'sum',
                  python_callable=summarize
          )
#определение последовательности выполнения задач
print_hi >> summarize_example
