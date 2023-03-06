#google cloud big query libraries
from google.cloud import bigquery
from google.oauth2 import service_account
import os


# get client based  on current username
def getBigQueryClient_TDMScenarios(): 

    if os.getlogin()=='Cday':
        key_path = r"C:\Users\cday\tdm-scenarios-c90ba30c3c5d.json"
    elif os.getlogin()=='bhereth':
        key_path = r"C:\Users\bhereth\tdm-scenarios-a85044dbbfd3.json"
    elif os.getlogin()=='sswim':
        key_path = r"C:\Users\sswim\tdm-scenarios-a5ce45fae4b0.json"

    credentials = service_account.Credentials.from_service_account_file(
        filename = key_path, scopes=["https://www.googleapis.com/auth/cloud-platform"],
    )
    
    return bigquery.Client(credentials=credentials, project=credentials.project_id,)

