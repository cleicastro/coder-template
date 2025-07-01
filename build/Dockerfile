FROM ghcr.io/cleicastro/archlinux-devcontainer:latest

ARG	USER=coder

RUN	useradd --groups wheel --no-create-home --shell /bin/bash ${USER} \
	&& echo "${USER} ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers \
	&& chmod 0440 /etc/sudoers

USER ${USER}

WORKDIR	/home/${USER}