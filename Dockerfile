FROM ubuntu:latest

# for certbot to work uninterrupted
ENV TZ=Europe/Berlin
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt-get update && apt-get install -y tzdata

RUN apt-get install -y sudo git make vim
RUN useradd -m tester && echo "tester:pass" | chpasswd && usermod -aG sudo tester && chown -R tester:tester /home/tester
USER tester

RUN echo 'alias l="ls -lhA"' >> /home/tester/.bash_aliases
RUN echo 'export PATH=$HOME/.local/bin:$PATH' >> /home/tester/.bash_aliases

RUN mkdir -p /home/tester/.local/bin
COPY --chown=tester:tester ./wdt /home/tester/.local/bin/wdt
RUN mkdir -p /home/tester/mywebapp
WORKDIR /home/tester/mywebapp

ENV SHELL /bin/bash
CMD ["/bin/bash"]
