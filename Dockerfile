FROM ubuntu
MAINTAINER HyprIoT <info@hypriot.com>

RUN apt-get update && \
apt-get install -y git-core openssh-client \
ruby-bundler && \
apt-get clean

ENV PI black-pearl

#RUN git clone https://github.com/hypriot/rpi-image-builder.git /test/
COPY ./test/ /test/
WORKDIR /test/
RUN gem install bundler && \
bundle install

ENTRYPOINT ["bin/rspec"]
CMD ["spec/hypriotos-image"]
#CMD ["spec/hypriotos-docker"]
