# -*- coding: utf-8 -*-
#!/usr/bin/python
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT 
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : protractor_rest.py
## Author : Denny <contact@dennyzhang.com>
## Description :
## --
## Created : <2016-05-29>
## Updated: Time-stamp: <2017-09-04 18:55:32>
##-------------------------------------------------------------------
# pip install flask
# export FLASK_DEBUG=1

import os, commands
from datetime import datetime

from flask import Flask
from flask import request, send_file, render_template

app = Flask(__name__)

WORKING_DIR = '/opt/protractor'

#################################################################################
def update_conf_js(conf_js, protract_js_file):
    import re
    conf_js = re.sub(r"\n *specs:.*",
                     " specs: ['%s']" % protract_js_file, conf_js)
    return conf_js

def make_tree(path):
    tree = dict(name=os.path.basename(path), children=[])
    try: lst = os.listdir(path)
    except OSError:
        pass #ignore errors
    else:
        for name in lst:
            fn = os.path.join(path, name)
            if os.path.isdir(fn):
                tree['children'].append(make_tree(fn))
            else:
                tree['children'].append(dict(name=name))
    return tree
#################################################################################
# curl -v -F conf_js=@/tmp/conf.js protractor_js=@/tmp/protractor.js  http://127.0.0.1:5000/protractor_request
@app.route("/protractor_request", methods=['POST'])
def protractor_request():
    print("Accept request")
    if os.path.exists(WORKING_DIR) is False:
        os.mkdir(WORKING_DIR)

    tmp_request_id = datetime.now().strftime('%Y-%m-%d_%H-%M-%S')
    protractor_js_file = "%s/%s.js" % (WORKING_DIR, tmp_request_id)
    conf_js_file = "%s/%s-conf.js" % (WORKING_DIR, tmp_request_id)

    f = request.files['protractor_js']
    f.save(protractor_js_file)

    f = request.files['conf_js']
    conf_js = update_conf_js(f.read(), protractor_js_file)
    open(conf_js_file, "wab").write(conf_js)

    # Run protractor Command
    cmd = "protractor %s" % (conf_js_file)
    print(cmd)
    os.chdir(WORKING_DIR)
    status, output = commands.getstatusoutput(cmd)

    # remove temporarily files
    os.remove(conf_js_file)
    os.remove(protractor_js_file)

    # TODO: return http code
    return output

@app.route('/get_image/<filename>', methods=['GET'])
def get_image(filename):
    if filename == "all":
        # If filename is not given, list images under working_dir
        return render_template("%s/dirtree.html" % (WORKING_DIR), tree = make_tree(WORKING_DIR))
    else:
        return send_file("%s/%s" % (WORKING_DIR, filename), mimetype='image/png')

if __name__ == "__main__":
    flask_port = "4445"
    app.run(host="0.0.0.0", port=int(flask_port))
## File : protractor_rest.py ends
