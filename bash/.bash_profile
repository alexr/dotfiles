	
### RUBY ###
# Load RVM into a shell session *as a function*
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"
# Add RVM to PATH for scripting
PATH=$PATH:$HOME/.rvm/bin

if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi


### HASKELL ###
# ghc-pkg-reset
# Removes all installed GHC/cabal packages, but not binaries, docs, etc.
# Use this to get out of dependency hell and start over, at the cost of some rebuilding time.
# From https://www.fpcomplete.com/user/simonmichael/how-to-cabal-install
function ghc-pkg-reset() {
    read -p 'erasing all your user ghc and cabal packages - are you sure (y/n) ? ' ans
    test x$ans == xy && ( \
        echo 'erasing directories under ~/.ghc'; rm -rf `find ~/.ghc -maxdepth 1 -type d`; \
        echo 'erasing ~/.cabal/lib'; $(__git_ps1 " (%s)")rm -rf ~/.cabal/lib; \
        # echo 'erasing ~/.cabal/packages'; rm -rf ~/.cabal/packages; \
        # echo 'erasing ~/.cabal/share'; rm -rf ~/.cabal/share; \
        )
}

### GIT ###
# tweak git colors to fit my color scheme (and match other environments)
git config --global color.status.untracked "blue normal bold"
git config --global color.status.changed "blue normal bold"
git config --global color.status.added "green normal bold"


export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced


PATH=$PATH:/usr/local/smlnj-110.75/bin
PATH=$PATH:$HOME/Library/Haskell/bin
export PATH

# Load ~bash_prompt, ~/.aliases, ~/.functions, ~/.git-prompt.sh, ~/.git-completion.bash, ~/z.sh,
for file in ~/.{functions,git-prompt.sh,git-completion.bash,z.sh,aliases,bash_prompt}; do
    [ -r "$file" ] && source "$file"
done
unset file
