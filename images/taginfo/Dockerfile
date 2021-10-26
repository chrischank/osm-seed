FROM ruby:2.7

ENV workdir /apps

RUN apt-get update -y
RUN apt-get dist-upgrade -u -y

# Install Taginfo site
RUN apt-get -y install \
    curl \
    jq \
    pbzip2 \
    sqlite3 \
    sqlite3-pcre \
    ruby-passenger \
    libapache2-mod-passenger \
    unzip \
    zip
# ruby \
# ruby-dev \
# Install Taginfo tools
RUN apt-get -y install \
    cmake \
    cmake-curses-gui \
    libbz2-dev \
    libexpat1-dev \
    libgd-dev \
    libicu-dev \
    libosmium2-dev \
    libprotozero-dev \
    libsqlite3-dev \
    make \
    zlib1g-dev \
    ca-certificates

# ENV RUBY_VERSION $(ruby -e "puts RUBY_VERSION.split('.')[0..1].join('.')")

# # Packages needed for running in uWSGI application server
# RUN apt-get install -y \
#     uwsgi-core \
#     uwsgi-plugin-rack-ruby$RUBY_VERSION

# # Packages needed for running under Apache
# RUN apt-get install -y \
#     apache2 \
#     libapache2-mod-passenger \
#     ruby-passenger

# Other useful packages
RUN apt-get install -y \
    git \
    osmium-tool \
    pyosmium \
    rsync \
    tmux \
    zsh

RUN apt-get clean

# Install Taginfo
RUN git clone https://github.com/taginfo/taginfo.git $workdir/taginfo
WORKDIR $workdir/taginfo
RUN echo "gem 'thin' " >>Gemfile
RUN gem install bundler
RUN bundle install

# Install taginfo-tools
# RUN git clone https://github.com/taginfo/taginfo-tools.git $workdir/taginfo-tools
# WORKDIR $workdir/taginfo-tools
# RUN git submodule update --init
# RUN mkdir build && cd build && cmake .. && make

# Install taginfo-tools
WORKDIR $workdir
RUN git clone https://github.com/osmcode/libosmium
RUN git clone https://github.com/mapbox/protozero
RUN git clone https://github.com/taginfo/taginfo-tools

WORKDIR $workdir/taginfo-tools
RUN git submodule update --init

RUN mkdir $workdir/build
WORKDIR $workdir/build

RUN cmake -DCMAKE_BUILD_TYPE=Release \
    -DOSMIUM_INCLUDE_DIR=../libosmium/include \
    -DPROTOZERO_INCLUDE_DIR=../protozero/include \
    ../taginfo-tools

RUN make -j2

RUN apt-get install -y nano vim

COPY start.sh $workdir/
WORKDIR $workdir/
CMD $workdir/start.sh
