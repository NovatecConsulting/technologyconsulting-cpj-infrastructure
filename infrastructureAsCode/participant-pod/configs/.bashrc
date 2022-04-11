source <(kubectl completion bash)
complete -F __start_kubectl k
export KUBE_EDITOR="nano"
alias k=kubectl