# Build:
docker build -t ccp/rbmq-benchmark .

# Run
docker run --name rbmq-benchmark -p 9999:8000 -d ccp/rbmq-benchmark

# Bench
docker exec -it rbmq-benchmark bash /usr/local/bin/run_bench.sh

# Access it via
http://externalip:9999/publish-consume.html
