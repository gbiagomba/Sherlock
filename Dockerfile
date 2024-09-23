FROM kalilinux/kali-rolling:latest

# copy files to /app
WORKDIR /app
COPY . /app

# install necessary packages
RUN apt-get update
RUN apt-get install -y nodejs npm wget curl gnupg git python3 python3-pip
RUN git clone https://github.com/gbiagomba/Sherlock.git
RUN cd Sherlock
RUN bash "install.sh"

# start the app
ENTRYPOINT ["bash"]
CMD ["./sherlock.sh"]
