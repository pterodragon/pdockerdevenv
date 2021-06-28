export UID=$(id -u)
export GID=$(id -g)
export GIT_GLOBAL_USER_NAME="git_global_user_name"
export GIT_GLOBAL_USER_EMAIL="git_global_user_email"
export GIT_GLOBAL_USER_USER_NAME="git_global_user_user_name"
docker-compose -f $(dirname "$0")/docker-compose.yml build
docker-compose -f $(dirname "$0")/docker-compose.yml run pdockerdevenv zsh 
