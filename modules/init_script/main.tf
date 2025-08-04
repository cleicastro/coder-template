resource "coder_script" "dotfiles" {
  agent_id     = coder_agent.nodejs.id
  display_name = "Configuration environment for dev"
  icon         = "icon/terminal.svg"
  run_on_start = true
  script       = <<EOF
    #!/bin/sh

    if [ ! -d "/home/${var.username}/.tmux/plugins/tpm" ]; then
      git clone https://github.com/tmux-plugins/tpm /home/${var.username}/.tmux/plugins/tpm
    else
      echo "TPM is already installed."
    fi

    ZSH_CUSTOM="$${ZSH_CUSTOM:-$${HOME}/.oh-my-zsh/custom}"

    # Clone zsh-autosuggestions if not exist
    if [ ! -d "$${ZSH_CUSTOM}/plugins/zsh-autosuggestions" ]; then
      git clone https://github.com/zsh-users/zsh-autosuggestions.git "$${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
    fi

    # Clone zsh-syntax-highlighting if not exist
    if [ ! -d "$${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" ]; then
      git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"
    fi

    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

    # Install Dotfiles
    coder dotfiles -y ${var.dotfiles_uri}
  EOF
}