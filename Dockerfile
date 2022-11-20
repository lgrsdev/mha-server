FROM python:3.8
COPY hm.txt /tmp
CMD python -m http.server 7000 --directory /tmp/