import requests
import json
import os
from datetime import datetime
import argparse

parser = argparse.ArgumentParser(description='Create Grafana dashboards')
parser.add_argument('--subfolder', type=str, help='Name of the subfolder holding the log files')
args = parser.parse_args()
subfolder = args.subfolder

LOG_DIR = "/data/extracted_logs"
GRAFANA_URL = "http://grafana"
GRAFANA_ADMIN_USERNAME = os.getenv('GRAFANA_ADMIN_USERNAME')
GRAFANA_ADMIN_PASSWORD = os.getenv('GRAFANA_ADMIN_PASSWORD')
GRAFANA_API_KEY = os.getenv('GRAFANA_API_KEY')

HEADERS = {
    "Authorization": f"Bearer {GRAFANA_API_KEY}",
    "Content-Type": "application/json"
}

def create_folder(folder_name):
    folder_payload = {
        "title": folder_name
    }
    create_folder_url = f"{GRAFANA_URL}/api/folders"
    response = requests.post(create_folder_url, headers=HEADERS, json=folder_payload)
    if response.status_code == 200:
        print(f"Folder '{folder_name}' created successfully.")
    else:
        print(f"Failed to create folder '{folder_name}'. Status code: {response.status_code}")


create_folder(subfolder)

files = os.listdir(os.path.join(LOG_DIR, subfolder))

for file in files:
    file_title = str(file)[:60]
    dashboard_payload = {
        "title": file_title,
        "panels": [
            {
                "type": "logs",
                "datasource": "loki",
                "title": file_title,
                "targets": [
                    {
                        "expr": f'{{filename="{LOG_DIR}/{subfolder}/{file}"}} |= ""',
                        "refId": "A",
                        "datasource": "loki"
                    }
                ],
                "options": {
                    "showTime": False,
                    "showLabels": False,
                    "showCommonLabels": False,
                    "wrapLogMessage": False,
                    "prettifyLogMessage": False,
                    "enableLogDetails": True,
                    "dedupStrategy": "none",
                    "sortOrder": "Descending"
                },
                "gridPos": {
                    "x": 0,
                    "y": 0,
                    "h": 20,
                    "w": 24
                }
            }
        ]
    }

    create_dashboard_url = f"{GRAFANA_URL}/api/dashboards/db"
    response = requests.post(create_dashboard_url, headers=HEADERS, json={"dashboard": dashboard_payload})
    if response.status_code == 200:
        print(f"Dashboard '{file_title}' created successfully.")
    else:
        print(f"Failed to create dashboard '{file_title}'. Status code: {response.status_code}")
