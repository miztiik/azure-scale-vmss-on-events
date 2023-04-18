1- The GlobalArgs class can be refactored into a dictionary or use the namedtuple module. It will reduce the time and space complexity.

2- Since some of the environment variables are integers, they can be converted to integers during initialization.

3- Remove the try-except block in the send_msg function since the same exception is being raised anyway.

4- Replace the current log level variable with the logging.getLevelName() function to allow the code to accept string inputs for logging levels.

5- Remove unused global variables like 'end_time'

6- Instead of calling datetime.datetime.now() function twice, it can be called once and its result can be stored in a variable.

7- Instead of creating a dictionary in the while loop for every event, we can create it once outside of the loop, then update its value on each iteration.

8- Rather than calling random.getrandbits(1), bool(random.getrandbits(1)) can be used to convert it to a boolean value directly.

9- Replace the time.sleep(...) function call with time.sleep(GlobalArgs.WAIT_SECS_BETWEEN_MSGS) to make the wait time a variable.

10- Rename the lambda_handler function to something that describes what the function is doing, such as send_sales_events_to_sqs.

11- Remove the unnecessary resp variable from the lambda_handler function.

12- Change the log format to make it easier to read.