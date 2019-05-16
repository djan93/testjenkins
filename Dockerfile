FROM python:3.6.7

COPY ./whoami /whoami/

WORKDIR /whoami/

RUN pip install -r requirements.txt

ENTRYPOINT [ "python" ]

CMD [ "whoami.py" ]