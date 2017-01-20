from __future__ import absolute_import
from flask import Flask, send_file, json, redirect
from .arm import move_arm, set_light


app = Flask(__name__)


@app.route('/move/<duration>/<joint>/<value>')
def move(duration, joint, value):
    move_arm(int(duration), joint, value)
    return json.dumps({'status': 'OK'})


@app.route('/light/<value>')
def light(value):
    set_light(value)
    return json.dumps({'status': 'OK'})


@app.route('/')
def index():
    return send_file('static/index.html')


@app.route('/<path:path>')
def catchall(path):
    return redirect("/")


if __name__ == "__main__":
    app.run(port=80)
