from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime

login = 'max_b'
password = '96694155'
host = '94.26.239.237'
db = 'dwh'

url = 'https://docs.google.com/spreadsheets/d/13DNpxzSWU1OkJ0TI5481aWvkBXq7PmQnC9kneT4LJ9Y/edit?usp=sharing'

service_acc = {
    "type": "service_account",
    "project_id": "...",
    "private_key_id": "...",
    "private_key": "...",
    "client_email": "...",
    "client_id": "...",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url": "",
    "universe_domain": "googleapis.com"
}


def get_data(sheet_name):
    import gspread
    import pandas as pd

    client = gspread.service_account_from_dict(service_acc)
    spreadsheet = client.open_by_url(url)

    df = pd.DataFrame(
        spreadsheet.worksheet(sheet_name).get_all_records(
            value_render_option="UNFORMATTED_VALUE"
        )
    )
    return df


def load_to_db(df, table_name, schema_name):
    from sqlalchemy import create_engine

    engine = create_engine(f'postgresql+psycopg2://{login}:{password}@{host}/{db}')
    df.to_sql(table_name, engine, schema=schema_name, if_exists='replace', index=False)


def etl_from_gsheets():
    import pandas as pd

    df_q1_2025 = get_data('2025Q1')
    df_q2_2025 = get_data('2025Q2')
    df_q3_2025 = get_data('2025Q3')
    df_q4_2025 = get_data('2025Q4')
    df_q1_2026 = get_data('2026Q1')

    df_all = pd.concat(
        [df_q1_2025, df_q2_2025, df_q3_2025, df_q4_2025, df_q1_2026],
        ignore_index=True
    )

    df = df_all.rename(columns={
        'тип коммуникации': 'communication_type',
        'провайдер': 'provider',
        'тип отправки': 'sending_type',
        'тариф': 'tariff',
        'прайс': 'price'
    })

    load_to_db(
        df=df,
        table_name='crm_costs',
        schema_name='max_b'
    )


OWNER = "{{ OWNER }}"

with DAG(
    dag_id=f'load_google_sheets_data_2_{OWNER}',
    start_date=datetime(2026, 5, 16),
    schedule='0 6 * * *',
    catchup=False,
    tags=[OWNER],
    default_args={"owner": OWNER}
) as dag:
    load_google_sheets_data_2 = PythonOperator(
        task_id='load_google_sheets_data_2',
        python_callable=etl_from_gsheets
    )

load_google_sheets_data_2
