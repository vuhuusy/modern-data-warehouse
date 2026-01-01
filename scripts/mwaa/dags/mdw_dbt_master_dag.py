# Airflow DAG for running dbt on the mdw project using the athena adapter.
from pathlib import Path
import os
import logging

import pendulum
import cosmos
from cosmos import DbtDag, ProjectConfig, ProfileConfig, ExecutionConfig
from cosmos.config import ExecutionMode

logger = logging.getLogger(__name__)
logger.info("Cosmos Version: %s", cosmos.__version__)

# Timezone configuration
local_tz = pendulum.timezone("Asia/Saigon")

# Path configurations
mdw_dbt = Path("/usr/local/airflow/dags/dbt/mdw_dbt")
dbt_executable = f"{os.environ['AIRFLOW_HOME']}/dbt_venv/bin/dbt"

# Execution configuration using WATCHER mode to reduce Glue catalog API calls
venv_execution_config = ExecutionConfig(
    dbt_executable_path=str(dbt_executable),
    execution_mode=ExecutionMode.WATCHER
)

dbt_cosmos_dag = DbtDag(
    # dbt/cosmos-specific parameters
    project_config=ProjectConfig(mdw_dbt),
    profile_config=ProfileConfig(
        profile_name="mdw",
        target_name="dev",
        profiles_yml_filepath=mdw_dbt / "profiles.yml",
    ),
    execution_config=venv_execution_config,
    # Airflow DAG parameters
    schedule="5 0 * * *",  # At 00:05 Vietnam time (Asia/Saigon) every day
    start_date=pendulum.datetime(2026, 1, 1, tz=local_tz),
    catchup=False,
    dag_id="mdw_dbt_master_dag",
    max_active_tasks=1,  # Only allow one concurrent task
    max_active_runs=1,  # Only allow one concurrent run
    is_paused_upon_creation=False,  # Start running the DAG as soon as it's created
)
