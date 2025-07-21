# app/app.py

from flask import Flask
app = Flask(__name__)

@app.route('/')
def home():
    return "Automated CICD_ECR Deployment Working!"

@app.route('/')
def health():
    return "OK", 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
