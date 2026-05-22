#!/bin/sh
set -e

mkdir -p /app/uploads/photos /app/uploads/recus /app/uploads/documents /app/uploads/chat
chown -R spring:spring /app/uploads

exec su-exec spring:spring java -jar /app/app.jar
