## Setting up posh for the first time.

Edit PowerShell profile (may need to create dirs along the path):

```
> notepad $profile
```

Add following line to the profile, where username is your Windows login:

```
. "C:\Users\username\Documents\Github\dotfiles\posh\Microsoft.PowerShell_profile.ps1"
```

Restart PowerShell.

### Enabling 'DejaVu Sans Mono' for console window.

First make sure to download [DejaVu](http://dejavu-fonts.org/wiki/Download) fonts, and install into `\Windows\Fonts`.
Then from elevated posh window run `Enable-Console-Dejavu`.


## Using git subtree to manage components tracked in their own repositories.

`posz` and `posh-tf` are different repositories added here via git subtree.

These steps are base on a very informative [post](http://blogs.atlassian.com/2013/05/alternatives-to-git-submodule-git-subtree/) by Nicola Paolucci.

Adding `alexr/posz` repo as a subtree at `dotfiles/posz`.

1. Add the sub-project as a remote to refer to it in shorter form:

    ```
    git remote add -f alexr-posz https://github.com/alexr/posz.git
    ```

2. Add it as a subtree:

    ```
    git subtree add --prefix posh/posz alexr-posz master --squash 
    ```

3. Fetch repo from remote and pull it into the subtree folder.

    ```
    git fetch alexr-posz master
    git subtree pull --prefix posh/posz alexr-posz master --squash
    ```

Same for `alexr/posh-tf`.

```
git remote add -f alexr-posh-tf https://github.com/alexr/posh-tf.git

git subtree add --prefix posh/posh-tf alexr-posh-tf master --squash 

git fetch alexr-posh-tf master
git subtree pull --prefix posh/posh-tf alexr-posh-tf master --squash
```

Subsequent updates to those repos just need step 3.
