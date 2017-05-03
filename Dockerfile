FROM mongo

RUN apt-get update && apt-get install -y cron python-pip
RUN pip install awscli

ADD backup.sh /
CMD ["./backup.sh"]