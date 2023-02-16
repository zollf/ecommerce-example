FROM elixir:latest

WORKDIR /usr/app

COPY . .

RUN apt-get update -y && apt-get install -y build-essential inotify-tools 

RUN mix local.hex --force
RUN mix local.rebar --force