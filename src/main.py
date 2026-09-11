from flask import Flask, render_template, url_for
import os

# Static assets (images, css, the resume PDF) are served from CloudFront in
# front of S3 in production. STATIC_BASE_URL is set via env var to point at
# that CDN domain. When it's unset (e.g. local development), we fall back to
# Flask's own static file handling, serving straight out of static_local/.
app = Flask(__name__, static_folder="static_local", static_url_path="/static_local")

STATIC_BASE_URL = os.environ.get("STATIC_BASE_URL", "").rstrip("/")


@app.context_processor
def inject_static_url():
    def static_url(filename):
        if STATIC_BASE_URL:
            return f"{STATIC_BASE_URL}/{filename}"
        return url_for("static", filename=filename)

    return dict(static_url=static_url)


@app.route("/")
def index():
    return render_template("index.html")


@app.route("/about")
def about():
    return render_template("about.html")


if __name__ == "__main__":
    app.run(debug=True)
