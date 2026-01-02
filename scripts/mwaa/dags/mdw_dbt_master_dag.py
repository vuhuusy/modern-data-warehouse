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

# Environment configuration
# Set dbt_target in MWAA Airflow Configuration: env.dbt_target = dev (or prod)
dbt_target = os.environ.get("dbt_target", "dev")
logger.info("Using dbt target: %s", dbt_target)

# Path configurations
mdw_dbt = Path("/usr/local/airflow/dags/dbt/mdw_dbt")
dbt_executable = f"{os.environ['AIRFLOW_HOME']}/dbt_venv/bin/dbt"

# Execution configuration using WATCHER mode to reduce Glue catalog API calls
venv_execution_config = ExecutionConfig(
    dbt_executable_path=str(dbt_executable),
    execution_mode=ExecutionMode.WATCHER
)

project_config = ProjectConfig(
    dbt_project_path=mdw_dbt,
    manifest_path=f"s3://mdw-{dbt_target}-mwaa-artifacts/dbt/manifest.json",
    dbt_vars={
        "partition": "{{ ds_nodash }}",
    })

profile_config = ProfileConfig(
    profile_name="mdw",
    target_name=dbt_target,
    profiles_yml_filepath=mdw_dbt / "profiles.yml",
)

operator_args = {
    "dbt_cmd_global_flags": ["--cache-selected-only"],
}

dbt_cosmos_dag = DbtDag(
    # dbt/cosmos-specific parameters
    project_config=project_config,
    profile_config=profile_config,
    execution_config=venv_execution_config,
    operator_args=operator_args,
    # Airflow DAG parameters
    schedule="5 0 * * *",  # At 00:05 Vietnam time (Asia/Saigon) every day
    start_date=pendulum.datetime(2018, 1, 1, tz=local_tz),
    catchup=False,
    dag_id="mdw_dbt_master_dag",
    max_active_tasks=1,  # Only allow one concurrent task
    max_active_runs=1,  # Only allow one concurrent run
    is_paused_upon_creation=False,  # Start running the DAG as soon as it's created
)
