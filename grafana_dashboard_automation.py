import requests
import json
import os
from datetime import datetime
import argparse

parser = argparse.ArgumentParser(description='foo')
parser.add_argument('--subfolder', type=str, help='Name of the subfolder holding the log files')
args = parser.parse_args()
subfolder = args.subfolder

GRAFANA_URL = "http://grafana"
GRAFANA_ADMIN_USERNAME = os.getenv('GRAFANA_ADMIN_USERNAME')
GRAFANA_ADMIN_PASSWORD = os.getenv('GRAFANA_ADMIN_PASSWORD')
GRAFANA_API_KEY = os.getenv('GRAFANA_API_KEY')

HEADERS = {
    "Authorization": f"Bearer {GRAFANA_API_KEY}",
    "Content-Type": "application/json"
}

# Directory containing log folders
LOG_DIR = "/data/extracted_logs"  # Update with your log directory

# Get list of folders in the log directory
folders = [folder for folder in os.listdir(LOG_DIR) if os.path.isdir(os.path.join(LOG_DIR, folder))]

dashboard_payload = {
    "title": subfolder,
    "panels": []
}
# Get list of files in the folder
files = os.listdir(os.path.join(LOG_DIR, subfolder))
for file in files:
    panel_title = str(file)[:60]
    panel_payload = {
        "title": panel_title,
        "type": "logs",
        "datasource": "loki",
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
            "h": 8,
            "w": 24
        }
    }
    dashboard_payload["panels"].append(panel_payload)
# Create dashboard via Grafana API
create_dashboard_url = f"{GRAFANA_URL}/api/dashboards/db"
response = requests.post(create_dashboard_url, headers=HEADERS, json={"dashboard": dashboard_payload})
if response.status_code == 200:
    print(f"Dashboard '{subfolder}' created successfully.")
else:
    print(f"Failed to create dashboard '{subfolder}'. Status code: {response.status_code}")