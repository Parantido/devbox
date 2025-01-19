from flask import Flask
import os
from database import Database
from routes import auth_route, callback_route, init_routes
from config import logger

app = Flask(__name__)
app.secret_key = os.urandom(24)

# Initialize app before gunicorn workers
logger.info("Initializing auth service")
Database.wait_for_database()
client_secret = Database.get_client_secret()
init_routes(client_secret)
logger.info("Auth service initialization complete")

@app.route('/oauth')
def auth():
    return auth_route()

@app.route('/oauth/callback')
def callback():
    return callback_route()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=3000)
