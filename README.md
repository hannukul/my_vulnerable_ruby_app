# Demo app showing common Top 10 OWASP 2021 vulnerabilities

This app is made with Ruby and Sinatra.
It's my submission for Helsinki University's 'Cyber Security Base: Course Project I'

## How to run the app

1. Make sure you have docker installed

2. Clone the repository
git clone https://github.com/hannukul/my_vulnerable_ruby_app

3.  Build docker container
docker build -t sinatra-vuln-demo .

4.  Run docker container
docker run -p 4567:4567 sinatra-vuln-demo

5. Access localhost:4567 with web browser


