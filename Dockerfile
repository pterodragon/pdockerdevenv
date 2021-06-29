FROM ubuntu:20.04 as base
RUN apt-get update && DEBIAN_FRONTEND="noninteractive" apt-get install -y software-properties-common git ripgrep tree curl bear build-essential cmake meld neovim zsh
RUN apt-get install -y make libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev
RUN apt-get install -y tmux
RUN apt-get install -y ccls
RUN apt-get install -y locales locales-all
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

FROM base as base-resources
RUN mkdir -p ~/Documents/github
RUN git clone https://github.com/pterodragon/config-files ~/Documents/github/config-files
# RUN git clone https://github.com/pyenv/pyenv.git ~/.pyenv
RUN git clone https://github.com/pyenv/pyenv.git ~/Documents/github/pyenv
# mind the pyenv root
# RUN git clone https://github.com/pyenv/pyenv-virtualenv.git $(pyenv root)/plugins/pyenv-virtualenv
RUN git clone https://github.com/pyenv/pyenv-virtualenv.git ~/Documents/github/pyenv-virtualenv
RUN git clone https://github.com/gpakosz/.tmux.git ~/Documents/github/tmux

FROM base as main

# pass in your own user when building
ARG UNAME=testuser
ARG UID
ARG GID
RUN groupadd -g $GID -o $UNAME
RUN useradd -m -u $UID -g $GID -o -s /bin/bash $UNAME
USER $UNAME
CMD /bin/bash

ENV PYENV_ROOT "/home/$UNAME/.pyenv"
ENV PATH "$PYENV_ROOT/bin:$PATH"
ARG PYENV_DEFAULT_VERSION=3.9.5

# copy resources & config files
RUN mkdir -p ~/Documents/github
COPY --from=base-resources --chown=$UID:$GID /root/Documents/github /home/$UNAME/Documents/github/
RUN cp -r ~/Documents/github/config-files/. ~/

# install pyenv
COPY --from=base-resources --chown=$UID:$GID /root/Documents/github/pyenv /home/$UNAME/.pyenv
RUN echo $PATH
RUN pyenv install $PYENV_DEFAULT_VERSION
COPY --from=base-resources --chown=$UID:$GID /root/Documents/github/pyenv-virtualenv $PYENV_ROOT/plugins/pyenv-virtualenv
RUN pyenv virtualenv $PYENV_DEFAULT_VERSION general
RUN pyenv global general

# install node, required before neovim plugins
ENV NVM_DIR /usr/local/nvm
USER root
RUN mkdir -p $NVM_DIR
ENV NODE_VERSION 14.17.1
RUN curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
RUN bash -c "source $NVM_DIR/nvm.sh && nvm install $NODE_VERSION && nvm alias default $NODE_VERSION && nvm use default"
ENV NODE_PATH $NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH
RUN node -v
RUN npm -v
RUN npm install --global yarn
USER $UNAME

# tmux
RUN cp -r ~/Documents/github/tmux ~/.tmux
RUN ln -s -f .tmux/.tmux.conf ~

# zsh
RUN rm -r ~/.oh-my-zsh  # add it later
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
RUN git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
RUN cp -r ~/Documents/github/config-files/.oh-my-zsh/* ~/.oh-my-zsh/
ENV PATH $PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH

# neovim & plugins
RUN cp ~/Documents/github/config-files/.zshrc ~/  # for some reason this is needed
RUN pip3 install neovim  # PATH has to have pip3 by pyenv
RUN pip3 install jedi
RUN sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
RUN nvim --headless +"PlugInstall" +qa
RUN mkdir -p ~/.config/coc/extensions
RUN cd ~/.config/coc/extensions && yarn add coc-pyright

# git configs
ARG GIT_GLOBAL_USER_NAME
ARG GIT_GLOBAL_USER_EMAIL
ARG GIT_GLOBAL_USER_USER_NAME
RUN git config --global user.name $GIT_GLOBAL_USER_NAME
RUN git config --global user.email $GIT_GLOBAL_USER_EMAIL
RUN git config --global user.username $GIT_GLOBAL_USER_USER_NAME
LABEL VERSION="0.0.1"


# to build
# export UID=$(id -u)
# export GID=$(id -g)
# docker-compose build
