import requests
from bs4 import BeautifulSoup
import shutil
"""
    The script is not working correctly as of right now, the file gets sent but can't be read from the server.
"""
superset_url = 'http://localhost:8088/'
print(superset_url)

shutil.make_archive("import_dashboards", 'zip', "./docker_entrypoints/superset/import_dashboards")

session = requests.Session()

# get CSRF token
response = session.get(superset_url + "login/")
soup = BeautifulSoup(response.text, "html.parser")
csrf_token = soup.find("input", {"id": "csrf_token"})["value"]

# get cookies
cookies = session.post(
    superset_url + "login/",
    data=dict(username='admin', password='admin', csrf_token=csrf_token),
)

request_body = {
    'overwrite' : True,
    'passwords' : {"databases/MyDatabase.yaml": "my_password"}
}
request_files = {
    'formData' : open("dashboard_export_20230818T193752.zip", "rb"),
}

req = session.post(
    superset_url + "api/v1/dashboard/import",
    files=request_files,
    data=request_body,
    headers={"X-CSRFToken": csrf_token},
)

print(req.content)