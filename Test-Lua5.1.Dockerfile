FROM ubuntu:16.04

# Install package dependencies
#   - Lua plus C headers for LuaRocks modules
#   - LuaRocks
RUN apt-get update && apt-get install -y \
    lua5.1 \
    liblua5.1-dev \
    luarocks

# Install LuaRocks modules required for testing
RUN luarocks install busted
RUN luarocks install bit32

# Add this project
ADD . /app
WORKDIR /app
