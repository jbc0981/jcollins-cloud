from flask import Flask, render_template, send_file, abort
from google.cloud import storage
import tempfile
import os

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

@app.route('/static/<path:filename>')
def serve_static_file(filename):
    """Serve static files from Google Cloud Storage."""
    try:
        # Get the bucket
        bucket = storage_client.get_bucket(BUCKET_NAME)
        
        # Get the blob (file object) from GCS
        blob = bucket.blob(filename)
        
        # Check if the file exists in GCS
        if not blob.exists():
            abort(404, description="File not found")
        
        # Download the file to a temporary location
        temp_file = tempfile.NamedTemporaryFile(delete=False)
        blob.download_to_filename(temp_file.name)
        
        # Serve the file
        return send_file(temp_file.name)
    
    except Exception as e:
        abort(500, description=str(e))
    finally:
        # Cleanup the temporary file after serving it
        if os.path.exists(temp_file.name):
            os.remove(temp_file.name)

if __name__ == "__main__":
    app.run(debug=True)