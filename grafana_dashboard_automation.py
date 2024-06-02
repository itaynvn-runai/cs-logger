import requests
import json
import os
from datetime import datetime
import argparse

parser = argparse.ArgumentParser(description='foo')
parser.add_argument('--subfolder', type=str, help='Name of the subfolder holding the log files')
args = parser.parse_args()
subfolder = args.subfolder

now = datetime.now()
timestamp = now.strftime('%Y%m%d%H%M%S')

# Grafana API URL for creating API keys
GRAFANA_URL = "http://grafana:3000"  # Update with your Grafana URL
api_url = f"{GRAFANA_URL}/api/auth/keys"

# Basic authentication credentials (username and password)
username = os.getenv('GRAFANA_ADMIN_USERNAME')
password = os.getenv('GRAFANA_ADMIN_PASSWORD')

# Data payload for creating the API key
data = {
    'name': f'MyAPIKey{timestamp}',  # Replace with your desired API key name
    'role': 'Admin'       # Replace with the desired role (e.g., Admin, Editor, Viewer)
}

# Headers for the HTTP request
headers = {
    'Content-Type': 'application/json'
}

# Perform the HTTP POST request to create the API key
response = requests.post(api_url, headers=headers, auth=(username, password), data=json.dumps(data))

# Check the response status
if response.status_code == 200:
    print('API key created successfully!')
    api_key_info = response.json()
    print('API Key ID:', api_key_info.get('id'))
    API_KEY = api_key_info.get('key')
    print('API Key:', API_KEY)
else:
    print('Failed to create API key:', response.status_code, response.text)

# Grafana API details
HEADERS = {
    "Authorization": f"Bearer {API_KEY}",
    "Content-Type": "application/json"
}

# Directory containing log folders
LOG_DIR = "/logs/extracted_logs"  # Update with your log directory

# Get list of folders in the log directory
folders = [folder for folder in os.listdir(LOG_DIR) if os.path.isdir(os.path.join(LOG_DIR, folder))]

dashboard_payload = {
    "title": subfolder,
    "panels": []
}
# Get list of files in the folder
files = os.listdir(os.path.join(LOG_DIR, subfolder))
for file in files:
    panel_title = file.replace("-", " ").title()
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