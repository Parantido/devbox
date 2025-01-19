import mysql.connector
import time
from config import Config, logger

class Database:
    @staticmethod
    def wait_for_database():
        max_retries = 30
        retry_interval = 10

        for attempt in range(max_retries):
            try:
                logger.info(f"Attempting database connection (attempt {attempt + 1}/{max_retries})")
                conn = mysql.connector.connect(
                    host=Config.DB_HOST,
                    user=Config.DB_USER,
                    password=Config.DB_PASS,
                    database=Config.DB_NAME
                )
                conn.close()
                logger.info("Successfully connected to database")
                return True
            except mysql.connector.Error as err:
                logger.warning(f"Database connection failed: {err}")
                logger.info(f"Retrying in {retry_interval} seconds...")
                time.sleep(retry_interval)

        error_msg = "Could not connect to database after maximum retries"
        logger.error(error_msg)
        raise Exception(error_msg)

    @staticmethod
    def get_client_secret():
        logger.info("Attempting to retrieve client secret from database")
        try:
            conn = mysql.connector.connect(
                host=Config.DB_HOST,
                user=Config.DB_USER,
                password=Config.DB_PASS,
                database=Config.DB_NAME
            )
            cursor = conn.cursor(dictionary=True)
    
            query = """
                SELECT SECRET 
                FROM CLIENT
                WHERE CLIENT_ID = %s AND REALM_ID = (
                    SELECT id FROM REALM WHERE name = %s
                )
            """
            params = (Config.KEYCLOAK_CLIENT_ID, Config.KEYCLOAK_REALM)
            
            logger.debug(f"Executing query with params: CLIENT_ID={Config.KEYCLOAK_CLIENT_ID}, REALM={Config.KEYCLOAK_REALM}")
            cursor.execute(query, params)
    
            secret_result = cursor.fetchone()
    
            if not secret_result:
                error_msg = "Client secret not found in database"
                logger.error(error_msg)
                raise Exception(error_msg)
    
            logger.info("Successfully retrieved client secret")
            logger.debug(f"Secret length: {len(secret_result['SECRET'])}")
            
            cursor.close()
            conn.close()
    
            return secret_result['SECRET']
    
        except mysql.connector.Error as err:
            logger.error(f"Database error while retrieving client secret: {err}")
            raise
        except Exception as e:
            logger.error(f"Error retrieving client secret: {e}")
            raise
