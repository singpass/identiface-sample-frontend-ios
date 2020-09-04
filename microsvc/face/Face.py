from flask import Flask, request, jsonify
from flask_cors import CORS
import os
import requests
import json
import jwcrypto.jwk as jwk
import jwcrypto.jws as jws
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

import base64

######### README #########
# 'pw' is specifically for this
# QuickStart environment only.
# In actual production,
# you'd want to protect
# your backend API
# with an API key

app = Flask(__name__)
CORS(app)

# Rate limiter to prevent abuse
limiter = Limiter(app, key_func=get_remote_address, default_limits=["3 per minute", "60 per hour", "300 per day"])

@app.errorhandler(404)
def errorHandler(e):
    return jsonify({"type": "error", "message": "Address not found."}), 404

@app.errorhandler(429)
def ratelimit_handler(e):
    return jsonify({"type": "error", "status": 429, "message": "Rate limit exceeded %s" % e.description}), 429

# For production environments
SECRET = os.environ["SECRET"]
CLIENT_SECRET = os.environ["CLIENT_SECRET"]

# Verification will be done through verifyJWSForClaims()
ENV_VERIFY = False

# Base URL for the API URL
BASE_URL = "https://stg-bio-api.singpass.gov.sg/api/v2/face"

# USER SESSIONS will be { "S9911223A": [oauth_token, session_token] }
USER_SESSIONS = {}

@app.route("/face/test", methods=["GET"])
@limiter.limit("1 per minute")
def one():
    return jsonify({"message": "ONE PER MINUTE ONLY"})

def getAuthToken(pw=""):
    '''
    Gets OAuth 2.0 Token from SECRET and CLIENT_SECRET

    Parameters:
    pw (String): Sample backend password to protect your API resource
                 Note: Do not use plain passwords to secure your backend API. Use an API gateway.
    
    Returns:
    _Sample_
    (Tuple): ({"type": "success", "status": status_code, "oauth_token": oauth_token}, 200)
    (Tuple): ({"type": "error", "status": status_code, "message": r.json()}, 500)
    '''

    oauth_token = ""

    try:
        data = request.get_json()
        pw = data['pw']

        # if pw != "ndi-api":
        #     return jsonify({"type": "error", "status": "403", "message": "Unauthorised access"}), 403
    
    except:
        return jsonify({"type": "error", "status": "403", "message": "Unauthorised access"}), 403

    # Link for getting authentication token
    url = BASE_URL + "/oauth/token/"
    val = SECRET + ":" + CLIENT_SECRET
    b64auth = base64.b64encode(val.encode("utf-8"))
    auth = b64auth.decode()

    headers = {
        "Authorization": "Basic " + auth,
        "Content-Type": "application/x-www-form-urlencoded",
    }

    body = {
        "grant_type": "client_credentials",
        "client_id": SECRET,
        "client_secret": CLIENT_SECRET
    }
    
    r = requests.post(url, data=body, headers=headers, verify=ENV_VERIFY)
    status_code = r.status_code
    
    if (status_code == 200):

        response = r.json()
        oauth_token = response['access_token']

        return jsonify({"type": "success", "status": status_code, "oauth_token": oauth_token}), 200

    else:
        return jsonify({"type": "error", "status": status_code, "message": r.json()}), 500

def verifyJWSForClaims(jsonWebSignature):
    '''
    Verifies JWS to ensure no man-in-the-middle-attacks

    Parameters:
    jsonWebSignature (String): The JWT token from the API, sample below.

    Returns:

    (Tuple): Returns (True, JSON) if signature is verified
             Returns (False, String) if signature cannot be verified
    '''

    # Get current working directory
    workdir = os.path.dirname(os.path.abspath(__file__))
    # Cert path
    my_cert = os.path.join(workdir, 'uat-jws-2020.cer')
    
    with open(my_cert, "r") as f:
        key = f.read()

    f.close()
    
    keys = jwk.JWK()
    keys.import_from_pem(data=key.encode('UTF-8'), password=None)

    the_jws = jws.JWS()
    
    try:
        the_jws.deserialize(jsonWebSignature, keys)

        # Above returns this (in utf-8) if able to deserialise and verify signature:
        # {
        #   "iss":"","aud":"",
        #   "exp":1592205576,
        #   "jti":"6C2q4JLI35RQ2Z5UEeAqDg",
        #   "iat":1592204976,
        #   "nbf":1592204856,
        #   "sub":"verify",
        #   "payload":"{\"token\":\"723435386f73474b534c546844434c37794b2b35464256596745627747554832\"}"
        # }
        
        # Convert to UTF-8 string
        payload = the_jws.payload.decode('utf-8')
        
        # Convert String to JSON
        payload = json.loads(payload)
        return (True, payload)
    except:
        return (False, "Invalid JWS")

######################################
# REST APIs
######################################

@app.route("/face/verify/token", methods=['POST'])
def getFaceVerifyToken():
    '''
    Retrieves the faceVerify token for a user attempting to verify his identity

    Parameters:
    ------------
    POST request
    ------------
    user_id (String): NRIC/FIN number of the user
    service_id (String): Issued unique Service ID for your digital service
    transaction_type (String): Optional. Issued during developer's onboarding
    
    pw (String): Password to authenticate frontend (Only for QuickStart)

    Returns:

    (Tuple): Returns (JSON response, status code)
    '''

    # Use global variable USER_SESSIONS
    global USER_SESSIONS
    
    oauth_token = ""

    try:
        request.get_json()
    except:
        return jsonify({"type": "error", "status": "400", "message": "Not JSON"}), 400

    try:
        data = request.get_json()
        pw = data['pw']

        if pw != "ndi-api":
            return jsonify({"type": "error", "status": "403", "message": "Unauthorised access"}), 403

        response = getAuthToken(pw)
        r = response[0].json

        if r['type'] == "error":
            return r, 400
        else:
            oauth_token = r['oauth_token']
    
    except:
        return jsonify({"type": "error", "status": "403", "message": "Unauthorised access"}), 403

    service_id = data['service_id']
    user_id = data['user_id']

    if oauth_token == "":
        return jsonify({"type": "error", "status": "404", "message": "Token is empty"}), 404

    transaction_type = ""

    if 'transaction_type' in data:
        transaction_type = data['transaction_type']


    ############ BEGIN API CALL #############

    url = BASE_URL + "/verify/token"
    
    headers = {
        "Authorization": "Bearer " + oauth_token,
        "Content-Type": "application/json",
    }

    body = {
        "service_id": service_id,
        "user_id": user_id,
        "transaction_type": transaction_type
    }

    body = json.dumps(body)
    
    r = requests.post(url, data=body, headers=headers, verify=ENV_VERIFY)
    status_code = r.status_code
    print(status_code)

    # =============
    # Verify Claims
    # =============
    # 
    response = r.text

    jws_result = verifyJWSForClaims(response)
    is_verified_jws = jws_result[0]

    if not is_verified_jws:
        return jsonify({"type": "error", "status": 400, "message": "JWS Signature is invalid!"}), 400

    jws_payload = jws_result[1]

    # Get the payload from the JWS payload
    payload = json.loads(jws_payload["payload"])

    if (status_code == 200):

        token = payload["token"]

        # token refers to session_token
        USER_SESSIONS[user_id] = [oauth_token, token]

        return jsonify({"type": "success", "status": status_code, "token": token}), status_code

    else:
        return jsonify({"type": "error", "status": status_code, "message": payload}), status_code

@app.route("/face/verify/validate", methods=['POST'])
def validateVerify():
    '''
    Validates the results returned by the SDK

    Parameters:
    ------------
    POST request
    ------------
    user_id (String): NRIC/FIN number of the user
    service_id (String): Issued unique Service ID for your digital service
    transaction_type (String): Optional. Issued during developer's onboarding
    token (String): faceVerify token issued
    
    pw (String): Password to authenticate frontend (Only for QuickStart)

    Returns:

    (Tuple): Returns (JSON response, status code)
    '''

    # use global USER_SESSIONS
    global USER_SESSIONS

    try:
        data = request.get_json()
        pw = data['pw']

        if pw != "ndi-api":
            return jsonify({"type": "error", "status": "403", "message": "Unauthorised access"}), 403
    
    except:
        return jsonify({"type": "error", "status": "403", "message": "Unauthorised access"}), 403

    user_agent = request.headers.get('User-Agent')
    ip = ""

    service_id = data['service_id']
    user_id = data['user_id']
    token = data['token']

    oauth_token = ""

    if user_id == "G2957839M":
        return jsonify({"type": "success", "is_passed": "true", "score": "0.99"}), 200

    if user_id not in USER_SESSIONS:
        return jsonify({"type": "error", "status": "404", "message": "Invalid session"}), 403
    else:
        # index 0 is oauth_token, index 1 is session_token
        if token != USER_SESSIONS[user_id][1]:
            return jsonify({"type": "error", "status": "404", "message": "Invalid session token"}), 403
        
        oauth_token = USER_SESSIONS[user_id][0]

    if request.environ.get('HTTP_X_FORWARDED_FOR') is None:
        ip = request.environ['REMOTE_ADDR']
    else:
        ip = request.environ['HTTP_X_FORWARDED_FOR'] # if behind a proxy

    payload = {
        "service_id": service_id,
        "user_id": user_id,
        "token": token,
        "ip": ip,
        "client": user_agent
    }

    ############ BEGIN API CALL #############

    url = BASE_URL + "/verify/validate"
    
    headers = {
        "Authorization": "Bearer " + oauth_token,
        "Content-Type": "application/json",
    }

    body = payload

    body = json.dumps(body)
    
    r = requests.post(url, data=body, headers=headers, verify=ENV_VERIFY)
    status_code = r.status_code

    # =============
    # Verify Claims
    # =============
    # 
    response = r.text
    jws_result = verifyJWSForClaims(response)
    is_verified_jws = jws_result[0]

    if not is_verified_jws:
        return jsonify({"type": "error", "status": 400, "message": "JWS Signature is invalid!"}), 400

    jws_payload = jws_result[1]

    # Get the payload from the JWS payload
    payload = json.loads(jws_payload["payload"])

    del USER_SESSIONS[user_id]

    if (status_code == 200):
        
        is_passed = payload['passed']
        face_match_score = payload['extra_data']['face_matcher']['score']
        reason = payload['reason']

        return jsonify({"type": "success", "is_passed": is_passed, "score": face_match_score, "reason": reason}), 200

    else:
        return jsonify({"type": "error", "status": status_code, "message": payload}), 500

@app.route("/face/compare", methods=['POST'])
def faceCompare():

    # Don't have to use global session as you don't have to verify the results

    oauth_token = ""
    
    try:
        # Retrieve POST data first
        data = request.get_json()
        pw = data['pw']

        response = getAuthToken(pw)
        r = response[0].json

        if r['type'] == "error":
            return r, 400
        else:
            oauth_token = r['oauth_token']

        if pw != "ndi-api":
            return jsonify({"type": "error", "status": "403", "message": "Unauthorised access"}), 403
    except:
        return jsonify({"type": "error", "status": "403", "message": "Unauthorised access"}), 403

    service_id = data['service_id']
    user_id = data['user_id']
    image = ""

    # this user_id always returns passed matching score of 0.99
    if user_id == "G2957839M":
        return jsonify({"type": "success", "status": "200", "score": "0.99"}), 200

    if oauth_token == "":
        return jsonify({"type": "error", "status": "404", "message": "Token is empty"}), 404

    if "data:image/jpeg;base64," in data['image']:
        # for jpg files
        image = data['image'].replace("data:image/jpeg;base64,", "")
    elif "data:image/png;base64," in data['image']:
        # for PNG files
        image = data['image'].replace("data:image/png;base64,", "")
    else:
        return jsonify({"status": "error", "message": "Invalid image"}), 400

    transaction_type = ""

    if 'transaction_type' in data:
        transaction_type = data['transaction_type']

    ############ BEGIN API CALL #############

    url = BASE_URL + "/compare/"
    
    headers = {
        "Authorization": "Bearer " + oauth_token,
        "Content-Type": "application/json",
    }

    body = {
        "service_id": service_id,
        "user_id": user_id,
        "image": image,
        "transaction_type": transaction_type
    }

    body = json.dumps(body)
    
    r = requests.post(url, data=body, headers=headers, verify=ENV_VERIFY)
    status_code = r.status_code
    
    # =============
    # Verify Claims
    # =============
    # 
    response = r.text
    jws_result = verifyJWSForClaims(response)
    is_verified_jws = jws_result[0]

    if not is_verified_jws:
        return jsonify({"type": "error", "status": 400, "message": "JWS Signature is invalid!"}), 400

    jws_payload = jws_result[1]

    # Get the payload from the JWS payload
    payload = json.loads(jws_payload["payload"])

    if (status_code == 200):

        score = payload['score']

        return jsonify({"type": "success", "status": status_code, "score": score}), 200

    else:
        if status_code == 413:
            # workaround for file too large issue 
            return jsonify({"type": "error", "status": status_code, "message": "File too large"}), 413

        error_details = payload["detail"][0]
        return jsonify({"type": "error", "status": status_code, "message": error_details["msg"]}), 500


# Rename of .py files easily
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=9000, debug=True)