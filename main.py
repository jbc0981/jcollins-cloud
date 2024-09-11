from flask import Flask, render_template, send_file, abort
from google.cloud import storage
import tempfile
import os
import logging

app = Flask(__name__)

storage_client = storage.Client()

# GCS Bucket Name
BUCKET_NAME = 'jcollins_cloud_static'

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/about')
def about():
    return render_template('about.html')

@app.route('/gcs-static/<path:filename>')
def serve_static_file(filename):
    try:
        # Get the GCS bucket
        bucket = storage_client.bucket(BUCKET_NAME)
        
        # Get the file (blob) from GCS
        blob = bucket.blob(filename)
        
        if not blob.exists():
            # Log an error if file not found
            app.logger.error(f"File not found in GCS: {filename}")
            abort(404, description="File not found")
        
        # Create a temporary file to download the blob
        temp_file = tempfile.NamedTemporaryFile(delete=False)
        blob.download_to_filename(temp_file.name)
        
        # Send the file with the original filename
        return send_file(
            temp_file.name,
            download_name=filename  # Use the original filename
        )

    except Exception as e:
        app.logger.error(f"Error serving file: {str(e)}")
        abort(500, description="Internal Server Error")

if __name__ == '__main__':
    app.run(debug=True)

if __name__ == "__main__":
    app.run(debug=True)