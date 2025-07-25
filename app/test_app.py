# app/test_app.py

from app import app

def test_home():
    tester = app.test_client()
    response = tester.get('/')
    assert response.status_code == 200
    assert b"Automated CICD_ECR Deployment Working!" in response.data
