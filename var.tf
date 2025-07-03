variable "dotfiles_uri" {
  type        = string
  description = "The URL to a dotfiles repository. (optional, when set, the user isn't prompted for their dotfiles)"

  default = "https://github.com/cleicastro/dotfiles"
}