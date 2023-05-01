FROM ubuntu:latest
RUN apt update && apt install -y sudo git make vim
RUN useradd -m trimclain && echo "trimclain:pass" | chpasswd && adduser trimclain sudo && chown -R trimclain:trimclain /home/trimclain
USER trimclain
COPY --chown=trimclain:trimclain ./test/.bash_aliases /home/trimclain/.bash_aliases
COPY --chown=trimclain:trimclain . /home/trimclain/wdt
RUN mkdir -p /home/trimclain/.local/bin/
# RUN git clone https://github.com/trimclain/wdt /home/trimclain/wdt && cd wdt
WORKDIR /home/trimclain/wdt
CMD ["/bin/bash"]
