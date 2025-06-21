#**run the container and test the build locally**:
docker run -d --name app1 -p 3000:3000 my-app-image

#**push an image to a Docker repository**:
docker login | 
docker push <my-docker-username>/my-app-image:latest
