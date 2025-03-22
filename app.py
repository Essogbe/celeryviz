from time import sleep
import celery
from celeryviz.log import attach_log_sender


from dotenv import load_dotenv
load_dotenv()

import os
rabbit_username = os.getenv("RABBITMQ_DEFAULT_USER")
rabbit_password = os.getenv("RABBITMQ_DEFAULT_PASS")

# Create a Celery app instance with broker login credentials
app = celery.Celery(
    'example_app',
    broker=f"pyamqp://{rabbit_username}:{rabbit_password}@web-ui//",  # Replace 'user' and 'password' with your broker credentials
    
)

# Attach logging for task monitoring
logger = celery.utils.log.get_task_logger(__name__)
attach_log_sender(app, logger)

@app.task
def add(x, y, z=0):
    sleep(3)
    # Calling the task asynchronously with new arguments
    add.apply_async(args=[x+1, y+100], kwargs={'z': z+10000}, countdown=5)
    
    sleep(3)
    logger.info("Adding %s + %s + %s." % (x, y, z))

    sleep(3)
    return x + y + z

# Register the task with the Celery app
app.register_task(add)
