FROM mongo

RUN apt-get update && apt-get install -y cron python-pip
RUN pip install awscli
RUN mkdir -p /backup/data

ADD backup.sh /
CMD ["./backup.sh"]