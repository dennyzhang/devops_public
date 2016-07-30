Wait For Requirement Met
=========================
Sleep with timeout mechanism

Sample
```
wait_for.sh "service apache2 status" 3
wait_for.sh "lsof -i tcp:8080" 10
wait_for.sh "nc -z -v -w 5 172.17.0.3 8443"
```
