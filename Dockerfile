ARG K8S_VERSION=1.31.3

FROM alpine/k8s:${K8S_VERSION}

RUN apk update && apk add --no-cache zsh k9s

## CONTAINER USER
ARG UID=1001
ENV UID=$UID
ARG GID=1001
ENV GID=$GID
ARG USER=devops
ENV USER=$USER

RUN apk update && apk add --no-cache sudo

RUN addgroup --system --gid $GID $USER
RUN echo "$USER ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$USER
RUN chmod 0440 /etc/sudoers.d/$USER
RUN adduser --system --uid $UID --ingroup $USER $USER

USER $USER
## END CONTAINER USER

# TODO: healthcheck

ARG WORKING_DIR=/var/src
ENV WORKDIR=$WORKING_DIR

WORKDIR $WORKDIR

CMD ["tail", "-f", "/dev/null"]
