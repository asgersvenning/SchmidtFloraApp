run=FALSE
if [ "$1" == "run" ]; then
    run=TRUE
fi
docker build -f Dockerfile --progress=plain -t schmidt_flora_app:latest . --build-arg run=$run
if [ "$run" == FALSE ]; then
  docker run -p 80:80 -e TERM=linux schmidt_flora_app:latest
fi