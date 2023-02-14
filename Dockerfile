FROM ubuntu:latest
WORKDIR /home/trimclain
RUN apt update && apt install software-properties-common -y && apt install -y sudo git make
RUN useradd -m trimclain && echo "trimclain:pass" | chpasswd && adduser trimclain sudo && chown -R trimclain:trimclain /home/trimclain
USER trimclain
CMD /bin/bash
RUN git clone https://github.com/trimclain/wdt /home/trimclain/wdt && cd wdt
