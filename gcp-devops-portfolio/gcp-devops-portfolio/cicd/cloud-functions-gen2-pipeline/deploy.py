#!/usr/bin/env python3
"""
Universal deployment driver for GCP Cloud Functions Gen2.

Deploys any number of functions defined in a per-environment YAML config,
so one Cloud Build pipeline can serve many repos/functions without
per-function build steps. Each function config can override any project
default via `fn.get("key") or config["project"]["key"]`.

Usage:
    python deploy.py --env stage --config gcp-variables-stage.yaml
"""
import argparse
import subprocess
import sys
import yaml


def load_config(path: str) -> dict:
    with open(path, "r") as f:
        return yaml.safe_load(f)


def build_deploy_command(fn: dict, project_defaults: dict) -> list:
    """Compose `gcloud functions deploy` args, falling back to project
    defaults whenever a function doesn't specify its own value."""
    get = lambda key: fn.get(key) or project_defaults[key]

    cmd = [
        "gcloud", "functions", "deploy", fn["name"],
        "--gen2",
        "--region", get("region"),
        "--project", get("project_id"),
        "--runtime", get("runtime"),
        "--source", fn["source_dir"],
        "--entry-point", fn["entry_point"],
        "--trigger-http" if fn.get("trigger") == "http" else "--trigger-topic",
        "--memory", str(get("memory_mb")) + "Mi",
        "--timeout", str(get("timeout_sec")) + "s",
        "--min-instances", str(fn.get("min_instances", 0)),
        "--max-instances", str(fn.get("max_instances", get("max_instances_default"))),
        "--service-account", get("service_account"),
        "--set-env-vars", ",".join(f"{k}={v}" for k, v in fn.get("env_vars", {}).items()),
    ]

    if fn.get("trigger") != "http":
        cmd += ["--trigger-topic", fn["trigger_topic"]]

    if fn.get("vpc_connector") or project_defaults.get("vpc_connector"):
        cmd += ["--vpc-connector", get("vpc_connector")]
        cmd += ["--egress-settings", fn.get("egress_settings", "PRIVATE_RANGES_ONLY")]

    return cmd


def deploy_function(fn: dict, project_defaults: dict, dry_run: bool = False):
    cmd = build_deploy_command(fn, project_defaults)
    print(f"[deploy] {fn['name']}: {' '.join(cmd)}")
    if dry_run:
        return
    result = subprocess.run(cmd, check=False)
    if result.returncode != 0:
        print(f"[FAILED] {fn['name']} exited with {result.returncode}")
        sys.exit(result.returncode)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--env", required=True)
    parser.add_argument("--config", required=True)
    parser.add_argument("--only", help="Comma-separated function names to limit deploy to")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    config = load_config(args.config)
    project_defaults = config["project"]
    functions = config["functions"]

    if args.only:
        wanted = set(args.only.split(","))
        functions = [f for f in functions if f["name"] in wanted]

    print(f"[deploy] Environment: {args.env} | Functions: {len(functions)}")
    for fn in functions:
        deploy_function(fn, project_defaults, dry_run=args.dry_run)

    print("[deploy] All functions deployed successfully.")


if __name__ == "__main__":
    main()
