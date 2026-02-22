from flask import Flask, render_template

# Create Flask app
# render_template looks for HTML files inside /templates folder
app = Flask(__name__)

# Route for homepage
@app.route("/")
def home():
    # renders templates/index.html
    return render_template("index.html")

if __name__ == "__main__":
    # host="0.0.0.0" — required so Docker exposes it outside container
    # port=5000 — Flask default port
    app.run(host="0.0.0.0", port=5000)