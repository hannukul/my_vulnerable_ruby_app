# Demo app showing common Top 10 OWASP 2021 vulnerabilities
It's a simple journaling app where users can register, login and add journal entries. 
This app is made with Ruby and Sinatra.
It's my submission for Helsinki University's 'Cyber Security Base: Course Project I'

## Vulnerabilities demoed
A01:2021 Broken Access Control<br>
A02:2021 Cryptographic Failures<br>
A03:2021 Injection<br>
A05:2021 Misconfiguration<br>
A10:2021 Server-side Request Forgery<br>

## How to run the app
1. Make sure you have docker installed
2. Clone the repository<br>
git clone https://github.com/hannukul/my_vulnerable_ruby_app<br>
cd my_vulnerable_ruby_app
3.  Build docker container<br>
docker build -t sinatra-vuln-demo .
4.  Run docker container<br>
docker run -p 4567:4567 sinatra-vuln-demo
5. Access localhost:4567 with web browser<br>

<br>Made by Hannu-Pekka Kulmala

