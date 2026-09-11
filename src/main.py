from datetime import datetime, timezone

from flask import Flask, redirect, render_template, url_for
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


@app.context_processor
def inject_current_year():
    # Keeps the footer's copyright year correct without needing a manual
    # yearly edit.
    return dict(current_year=datetime.now(timezone.utc).year)


@app.route("/")
def index():
    return render_template("index.html")


@app.route("/about")
def about():
    # The about-me content now lives on the home page; keep this route around
    # as a redirect so any old bookmarks/links don't just 404.
    return redirect(url_for("index"), code=301)


if __name__ == "__main__":
    app.run(debug=True)
