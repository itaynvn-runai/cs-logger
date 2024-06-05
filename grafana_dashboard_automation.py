import requests
import sys
import os
import argparse
import time
import datetime

parser = argparse.ArgumentParser(description='Create Grafana dashboards')
parser.add_argument('--mode', type=str, help='Operation mode: new, reset')
parser.add_argument('--subfolder', type=str, help='Name of the subfolder holding the log files')
args = parser.parse_args()
mode = args.mode
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
if mode == "reset":
    print(f"Resetting dashboards in folder '{subfolder}'...")
elif mode == "new":
    print(f"Creating new dashboards from folder '{subfolder}'...")
else:
    print("Unkown operation mode (should be 'new' or 'reset'), exitting")
    sys.exit(1)

unix_timestamp = subfolder[11:]
human_timestamp = datetime.datetime.fromtimestamp(unix_timestamp).strftime("%d/%m/%Y %H:%M")
folder_title = f"{subfolder} ({human_timestamp})"

while True:
    response = requests.post(f"{GRAFANA_URL}/api/folders", headers=HEADERS, json={"title": folder_title})
    if response.status_code == 200:
        print(f"Folder '{folder_title}' created successfully.")
        folder_uid = response.json().get("uid")
        break
    else:
        print(f"Failed to create folder '{folder_title}'.")
        print(f"Status code: {response.status_code}. Error message: {response.text}.")
        print("Retrying...")
        time.sleep(2)

files = os.listdir(os.path.join(LOG_DIR, subfolder))

for file in files:
    dashboard_payload = {
        "title": file,
        "panels": [
            {
                "type": "logs",
                "datasource": "loki",
                "title": file,
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
                "gridPos": {"x": 0, "y": 0, "h": 20, "w": 24}
            }
        ]
    }

    while True:
        response = requests.post(f"{GRAFANA_URL}/api/dashboards/db",
                                 headers=HEADERS,
                                 json={"dashboard": dashboard_payload, "folderUid": folder_uid})
        if response.status_code == 200:
            print(f"Dashboard '{file}' created successfully.")
            break
        else:
            print(f"Failed to create dashboard '{file}'.")
            print(f"Status code: {response.status_code}. Error message: {response.text}.")
            print("Retrying...")
            time.sleep(2)
