### Package deps, for build and devel phases
FROM whosgonna/dancer2-stack:tt-gazelle_latest-build AS package_deps

#RUN apk --no-cache add mariadb-dev

### Build phase, build our app and our app deps
FROM package_deps AS builder

COPY cpanfile* /app/
RUN cd /app && pdi-build-deps && ls

#COPY . /app/


### Create the "development" image
FROM builder AS devel

RUN apk --no-cache add jq

COPY --from=builder /deps/ /deps/
COPY --from=builder /app/ /app/

RUN cd /app && pdi-build-deps cpanfile.devel

### And we are done: this "development" image can be generated with:
###
###      docker build -t my-app-devel --target devel .
###
### You can then run it as:
###
###      cd your-app-workdir; docker run -it --rm -v `pwd`:/app my-app-devel
###


### Final phase: the runtime version - notice that we start from the stack image
FROM whosgonna/dancer2-stack:tt-gazelle_latest-runtime

ENV PLACK_ENV=production
#RUN apk --no-cache add mariadb-client

## deploy the application and dependancies into the runtime image:
COPY --from=builder /deps/ /deps/
COPY --from=builder /app/ /app/
COPY ./MyDancer/ /app/MyDancer

CMD [ "plackup", "--port", "5000", "--server", "Gazelle", "/app/MyDancer/bin/app.psgi"]
