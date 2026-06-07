name: Deploy Functions to Airflow

on:
  push:
    branches: [master]
    paths:
      - 'functions.py'  # Запускать только при изменениях файла functions.py
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      # Получаем список изменённых файлов в последнем коммите
      - name: Get changed files
        id: changed-files
        uses: tj-actions/changed-files@v35
        with:
          files: |
            functions.py

      - name: Create user folder on VM
        uses: appleboy/ssh-action@v1
        with:
          host: "95.213.230.26"
          username: "root"
          port: "22"
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          script: |
            mkdir -p "/home/apache-superset/airflow/dags/${{ secrets.OWNER }}/dags"

      # Копируем переименованные файлы в общую папку dags/ на ВМ
      - name: Copy functions to VM
        uses: appleboy/scp-action@v0.1.4
        with:
          host: "95.213.230.26"
          username: "root"
          port: "22"
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          source: "functions.py"
          target: "/home/apache-superset/airflow/dags/${{ secrets.OWNER }}/dags"
          
      # Создаём файл .env и записываем в него переменные
      - name: Create .env file on VM
        uses: appleboy/ssh-action@v1
        with:
          host: "95.213.230.26"
          username: "root"
          port: "22"
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          script: |
            cat > "/home/apache-superset/airflow/dags/${{ secrets.OWNER }}/dags/.env" << EOF
            login=${{ secrets.OWNER }}
            password=${{ secrets.DB_PASS }}
            EOF
