# Use an Alpine-based Python image
FROM python:3.8-alpine
# Set working directory
RUN mkdir /code
WORKDIR /code
# Install system dependencies
RUN apk update && \
    apk add --virtual build-deps gcc python3-dev musl-dev && \
    apk add postgresql-dev
# Update package lists and install Python
RUN apk update && apk add --no-cache python3

ENV PYTHONUNBUFFERED 1
# Install Python dependencies
COPY requirements.txt /code/
##RUN pip install --no-cache-dir -r requirements.txt
RUN pip install -r requirements.txt

# Make port 8001 available to the world outside this container
EXPOSE 8001

# Define environment variable
ENV NAME World

CMD ["python", "manage.py", "runserver", "0.0.0.0:8001"]
# RUN apk-get update && apk-get install -y postgresql-client
ADD ./ /code/

# Ensure the .env file is copied
COPY .env /code/.env