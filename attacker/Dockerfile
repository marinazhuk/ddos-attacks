FROM ubuntu

RUN apt-get -y update  \
    && apt-get install -y hping3 \
    && apt-get install -y php \
    && apt-get install -y iputils-ping



COPY slowloris.php opt/slowloris.php

CMD bash