FROM ubuntu

RUN apt-get -y update  \
    && apt-get -y install nginx \
     && apt-get -y install iptables \
        && apt-get -y install ufw


EXPOSE 80

CMD ["/usr/sbin/nginx", "-g", "daemon off;"]