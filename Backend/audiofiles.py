from flask import Flask, request, jsonify, send_file
from google.cloud import storage
import os
import tempfile

# Initialize Flask app
app = Flask(__name__)

# Set GCP Project and Bucket Name
GCP_PROJECT = "soundcolletive"
BUCKET_NAME = "uploaded_sounds"

# Initialize GCP Storage Client
storage_client = storage.Client(project=GCP_PROJECT)
bucket = storage_client.bucket(BUCKET_NAME)

@app.route("/upload", methods=["POST"])
def upload_audio():
    """Upload an audio file to the bucket."""
    if "file" not in request.files:
        return jsonify({"error": "No file part in the request"}), 400

    file = request.files["file"]
    if file.filename == "":
        return jsonify({"error": "No file selected"}), 400

    blob = bucket.blob(file.filename)
    blob.upload_from_file(file)
    return jsonify({"message": "File uploaded successfully", "filename": file.filename}), 201

@app.route("/list", methods=["GET"])
def list_audio_files():
    """List all audio files in the bucket."""
    blobs = bucket.list_blobs()
    files = [blob.name for blob in blobs]
    return jsonify({"files": files}), 200

@app.route("/download/<filename>", methods=["GET"])
def download_audio(filename):
    """Download an audio file from the bucket."""
    blob = bucket.blob(filename)
    if not blob.exists():
        return jsonify({"error": "File not found"}), 404

    temp_file = tempfile.NamedTemporaryFile(delete=False)
    blob.download_to_filename(temp_file.name)
    return send_file(temp_file.name, as_attachment=True, download_name=filename)

@app.route("/delete/<filename>", methods=["DELETE"])
def delete_audio(filename):
    """Delete an audio file from the bucket."""
    blob = bucket.blob(filename)
    if not blob.exists():
        return jsonify({"error": "File not found"}), 404

    blob.delete()
    return jsonify({"message": "File deleted successfully", "filename": filename}), 200

if __name__ == "__main__":
    os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = "soundcolletive.json"
    app.run(host="0.0.0.0", port=5000)