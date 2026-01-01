#!/bin/sh

export DBT_VENV_PATH="${AIRFLOW_HOME}/dbt_venv"
export DBT_PROJECT_PATH="${AIRFLOW_HOME}/dags/dbt"

python3 -m venv "${DBT_VENV_PATH}"

${DBT_VENV_PATH}/bin/pip install \
    dbt-core==1.10.17 \
    dbt-athena==1.9.5
