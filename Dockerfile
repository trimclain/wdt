FROM ubuntu:latest
RUN apt-get update && apt-get install -y sudo git make vim
RUN useradd -m tester && echo "tester:pass" | chpasswd && usermod -aG sudo tester && chown -R tester:tester /home/tester
USER tester
RUN echo 'export PATH=$HOME/.local/bin:$PATH' > /home/tester/.bash_aliases
RUN mkdir -p /home/tester/.local/bin/
# TODO: change to wdt after rewrite
COPY --chown=tester:tester ./wdt.sh /home/tester/.local/bin/wdt
WORKDIR /home/tester
CMD ["/bin/bash"]
