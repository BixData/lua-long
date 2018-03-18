FROM jimho/lua:5.3

# Install LuaRocks
RUN curl -sL http://luarocks.org/releases/luarocks-2.4.3.tar.gz -o luarocks.tar.gz
RUN tar zxpf luarocks.tar.gz
WORKDIR luarocks-2.4.3
RUN ./configure
RUN make bootstrap

# Install LuaRocks modules required for testing
RUN luarocks install busted
RUN luarocks install middleclass

# Add this project
ADD . /app
WORKDIR /app

# Run tests
#RUN busted -v
