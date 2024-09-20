#!/bin/bash

# Step 1: Update and Upgrade the system
sudo apt-get update
sudo apt-get upgrade -y

# Step 2: Install necessary packages
sudo apt-get install python3 python3-pip git curl -y

# Step 3: Install Speedtest (official version)
curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash
sudo apt-get install speedtest -y

# Step 4: Set up directories for the Flask app
mkdir -p ~/speedtest_web/static/icons
mkdir -p ~/speedtest_web/static/screenshots
mkdir -p ~/speedtest_web/static
mkdir -p ~/speedtest_web/templates

# Step 5: Download necessary images from GitHub
curl -o ~/speedtest_web/static/icons/favicon.png https://raw.githubusercontent.com/jakeharvey05/speedtest_web/41d5533772e6f411f6502b62420cf9ac8e36ffb1/icons/favicon.jpg
curl -o ~/speedtest_web/static/icons/icon-512x512.png https://raw.githubusercontent.com/jakeharvey05/speedtest_web/41d5533772e6f411f6502b62420cf9ac8e36ffb1/icons/icon-512x512.jpg
curl -o ~/speedtest_web/static/icons/12wdlogo.png https://raw.githubusercontent.com/jakeharvey05/speedtest_web/41d5533772e6f411f6502b62420cf9ac8e36ffb1/icons/12wdlogo.jpg
curl -o ~/speedtest_web/static/icons/icon-192x192.png https://raw.githubusercontent.com/jakeharvey05/speedtest_web/41d5533772e6f411f6502b62420cf9ac8e36ffb1/icons/icon-192x192.jpg
curl -o ~/speedtest_web/static/screenshots/wide_screenshot.png https://raw.githubusercontent.com/jakeharvey05/speedtest_web/41d5533772e6f411f6502b62420cf9ac8e36ffb1/screenshots/wide_screenshot.jpg
curl -o ~/speedtest_web/static/screenshots/mobile_screenshot.png https://raw.githubusercontent.com/jakeharvey05/speedtest_web/41d5533772e6f411f6502b62420cf9ac8e36ffb1/screenshots/mobile_screenshot.jpg

# Step 6: Create necessary files

# Creating app.py
cat <<EOT > ~/speedtest_web/app.py
from flask import Flask, render_template, jsonify, request, send_file
import subprocess
import json
from datetime import datetime
from fpdf import FPDF
import requests

app = Flask(__name__)

def get_wan_ip():
    try:
        ip = requests.get('https://api.ipify.org').text
    except Exception as e:
        ip = 'Unavailable'
    return ip

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/run_speedtest', methods=['POST'])
def run_speedtest():
    try:
        result = subprocess.run(['speedtest', '--format=json'], capture_output=True, text=True)
        result_json = json.loads(result.stdout)
        server = result_json['server']
        download_speed = (result_json['download']['bandwidth'] / 125000)
        upload_speed = (result_json['upload']['bandwidth'] / 125000)
        ping = result_json['ping']['latency']
        return jsonify(result=result.stdout, server=server, download=download_speed, upload=upload_speed, ping=ping)
    except Exception as e:
        return jsonify({"error": "Speedtest failed"}), 500

@app.route('/download_pdf', methods=['POST'])
def download_pdf():
    data = request.json
    wan_ip = get_wan_ip()

    pdf = FPDF()
    pdf.add_page()

    # Title
    pdf.set_font("Arial", size=18, style='B')
    pdf.cell(200, 10, txt="12 Woodfield Road Speedtest Results", ln=True, align="C")

    pdf.ln(10)  # Line break

    # Results Table (without headers)
    pdf.set_font("Arial", size=12)

    pdf.cell(60, 10, txt="Date & Time", border=1)
    pdf.cell(120, 10, txt=data['test_time'], border=1)
    pdf.ln(10)

    pdf.cell(60, 10, txt="WAN IP", border=1)
    pdf.cell(120, 10, txt=wan_ip, border=1)
    pdf.ln(10)

    pdf.cell(60, 10, txt="Test Server", border=1)
    pdf.cell(120, 10, txt=f"{data['server']['name']}, {data['server']['location']}", border=1)
    pdf.ln(10)

    pdf.cell(60, 10, txt="Ping", border=1)
    pdf.cell(120, 10, txt=f"{data['ping']} ms", border=1)
    pdf.ln(10)

    pdf.cell(60, 10, txt="Download Speed", border=1)
    pdf.cell(120, 10, txt=f"{data['download']} Mbps", border=1)
    pdf.ln(10)

    pdf.cell(60, 10, txt="Upload Speed", border=1)
    pdf.cell(120, 10, txt=f"{data['upload']} Mbps", border=1)
    pdf.ln(10)

    # Save the PDF
    pdf_file_path = "/tmp/speedtest_results.pdf"
    pdf.output(pdf_file_path)

    return send_file(pdf_file_path, as_attachment=True)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5555, debug=False)
EOT

# Creating index.html
cat <<'EOT' > ~/speedtest_web/templates/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>12WD SPEEDTEST</title>
    <link rel="manifest" href="/static/manifest.json">
    <!-- Favicon -->
    <link rel="icon" href="/static/icons/favicon.png" type="image/png">
    <!-- Google Fonts -->
    <link href="https://fonts.googleapis.com/css2?family=Open+Sans:wght@400&display=swap" rel="stylesheet">
    <style>
        body { 
            font-family: 'Open Sans', sans-serif; 
            background-color: #f4f4f9; 
            display: flex; 
            justify-content: center; 
            align-items: center; 
            height: 100vh; 
            margin: 0; 
        }
        .container { 
            background-color: #ffffff; 
            padding: 30px; 
            border-radius: 8px; 
            box-shadow: 0 4px 10px rgba(0, 0, 0, 0.1); 
            text-align: center; 
            width: 100%; 
            max-width: 400px; 
            min-height: 480px; 
            display: flex; 
            flex-direction: column; 
            justify-content: center; 
            align-items: center; 
        }
        h1 { 
            color: #333333; 
            font-size: 26px; 
            margin-bottom: 25px; 
        }
        button { 
            background-color: #017BFE; 
            color: #ffffff; 
            border: none; 
            padding: 15px 0; 
            border-radius: 5px; 
            font-size: 18px; 
            cursor: pointer; 
            margin-bottom: 20px; 
            width: 220px; 
            text-align: center; 
            align-self: center; 
            display: flex; 
            justify-content: center; 
            align-items: center;
        }
        button:hover { 
            background-color: #0056b3; 
        }
        .result-box { 
            background-color: #f1f1f1; 
            border-radius: 5px; 
            padding: 10px; 
            margin-bottom: 10px; 
            font-size: 18px; 
            color: #333333; 
            width: calc(100% - 20px); 
            text-align: center; 
        }
        .results { 
            width: 100%; 
        }
        .spinner { 
            margin-top: 20px; 
            border: 6px solid #f3f3f3; 
            border-radius: 50%; 
            border-top: 6px solid #017BFE; 
            width: 60px; 
            height: 60px; 
            animation: spin 1.5s linear infinite; 
            display: none; 
            margin-left: auto; 
            margin-right: auto; 
        }
        @keyframes spin { 
            0% { transform: rotate(0deg); } 
            100% { transform: rotate(360deg); } 
        }
    </style>
    <script>
        if ('serviceWorker' in navigator) {
            navigator.serviceWorker.register('/static/service-worker.js').then(function(registration) {
                console.log('ServiceWorker registration successful with scope: ', registration.scope);
            }).catch(function(error) {
                console.log('ServiceWorker registration failed: ', error);
            });
        }

        function runSpeedtest() {
            document.querySelector('button#start-speedtest').style.display = 'none';
            document.getElementById('spinner').style.display = 'block';
            document.getElementById('results').style.display = 'none';
            document.querySelector('button#download-pdf').style.display = 'none';  // Hide the Download PDF button when test starts
            fetch('/run_speedtest', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
            }).then(response => response.json()).then(data => {
                document.getElementById('spinner').style.display = 'none';
                const result = JSON.parse(data.result);
                const server = data.server;
                const testTime = new Date().toLocaleString();  // Use local time
                document.getElementById('results').innerHTML = `
                    <div class="result-box test-time"><strong>Test Date/Time:</strong> ${testTime}</div>
                    <div class="result-box server"><strong>Server:</strong> ${server.name}, ${server.location}</div>
                    <div class="result-box ping"><strong>Ping:</strong> ${data.ping} ms</div>
                    <div class="result-box download-speed"><strong>Download:</strong> ${data.download.toFixed(2)} Mbps</div>
                    <div class="result-box upload-speed"><strong>Upload:</strong> ${data.upload.toFixed(2)} Mbps</div>
                `;
                document.getElementById('results').style.display = 'block';
                document.querySelector('button#download-pdf').style.display = 'block';
                document.querySelector('button#start-speedtest').style.display = 'block';
            }).catch(error => {
                document.getElementById('spinner').style.display = 'none';
                alert("Error running Speedtest");
                document.querySelector('button#start-speedtest').style.display = 'block';
            });
        }

        function downloadPDF() {
            const resultData = {
                test_time: document.querySelector('.test-time').innerText.split(": ")[1],
                download: document.querySelector('.download-speed').innerText.split(" ")[1],
                upload: document.querySelector('.upload-speed').innerText.split(" ")[1],
                ping: document.querySelector('.ping').innerText.split(" ")[1],
                server: {
                    name: document.querySelector('.server').innerText.split(":")[1].split(",")[0].trim(),
                    location: document.querySelector('.server').innerText.split(",")[1].trim()
                }
            };

            fetch('/download_pdf', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(resultData)
            }).then(response => response.blob())
            .then(blob => {
                const url = window.URL.createObjectURL(blob);
                const a = document.createElement('a');
                a.href = url;
                const dateTime = resultData.test_time.replace(/[^0-9]/g, "_");
                a.download = `12WD_Speedtest_${dateTime}.pdf`;
                document.body.appendChild(a);
                a.click();
                a.remove();
            });
        }
    </script>
</head>
<body>
    <div class="container">
        <img src="/static/icons/12wdlogo.png" alt="Logo" class="logo">
        <h1>12WD SPEEDTEST</h1>
        <button id="start-speedtest" onclick="runSpeedtest()">START SPEEDTEST</button>
        <div id="spinner" class="spinner"></div>
        <div id="results" class="results"></div>
        <button id="download-pdf" style="display:none;" onclick="downloadPDF()">DOWNLOAD PDF</button>
    </div>
</body>
</html>
EOT

# Step 7: Set up the systemd service
sudo bash -c 'cat <<EOT > /etc/systemd/system/speedtest_web.service
[Unit]
Description=Speedtest Web Interface Flask App
After=network.target

[Service]
User=pi
WorkingDirectory=/home/pi/speedtest_web
ExecStart=/usr/bin/python3 /home/pi/speedtest_web/app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOT'

# Step 8: Install Flask
pip3 install Flask

# Step 9: Reload systemd, enable and start the speedtest_web service
sudo systemctl daemon-reload
sudo systemctl enable speedtest_web.service
sudo systemctl start speedtest_web.service

# Step 10: Get the local IP address
LOCAL_IP=$(hostname -I | awk '{print $1}')

# Step 11: Clear the terminal
clear

# Step 12: Display the success message with the local IP address
echo "Speedtest Web Interface setup is complete!"
echo "You can access it at http://$LOCAL_IP:5555"
