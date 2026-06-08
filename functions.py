import psycopg2
import logging
from airflow.models import Variable
import os
from dotenv import load_dotenv
load_dotenv()

login = os.environ['login']
password = os.environ['password']
logger = logging.getLogger(__name__)

host = Variable.get("host_dm")
db = 'dwh'

def db_con():
    "подключение к dwh"
    try:
        conn = psycopg2.connect(
        dbname=db,
        port = "5432",
        user=login,
        password=password,
        host=host
        )
    except Exception as e:
        logger.error(f'failed connect to db with error: {e}')
    return conn   

def execute_sql_script(file_path):
    "Запуск sql скрипта"
    con = db_con()
    cursor = con.cursor()
    with open(f'{file_path}.sql', 'r') as file:
        sql_script = file.read()
    try:
        cursor.execute(sql_script)
        con.commit()
        logger.info('successfully executed sql script')
        con.close()
    except Exception as e:
        con.rollback()
        con.close()
        logger.error(f'failed to execute sql script with error: {e}')
        raise e
