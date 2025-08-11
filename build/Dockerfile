FROM ghcr.io/cleicastro/archlinux-devcontainer:latest

ARG	USER=coder

RUN	useradd --groups wheel --no-create-home --shell $(which zsh) ${USER} \
	&& echo "${USER} ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers \
	&& chmod 0440 /etc/sudoers

USER ${USER}
WORKDIR	/home/${USER}

# Install TPM and Oh My Zsh
RUN git clone https://github.com/tmux-plugins/tpm /home/${USER}/.tmux/plugins/tpm \
&& sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"