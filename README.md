This is a fork that contains some personal changes that are useful for me.

Those are the following so far:

- vi mode indicator  
  <img src="https://github.com/user-attachments/assets/19a5c8fd-d1be-4117-96d1-aa1e49c1b242" height="80" style="vertical-align: baseline;" />
- nix mode indicator  
  <img src="https://github.com/user-attachments/assets/a9eac650-bd11-4840-9ee9-d80c436cbb0c" height="70" style="vertical-align: baseline;" />
- display the prompt output and the prompt input on separate lines. (this still  
  needs to be changed so its configurable and not by default)  
  <img src="https://github.com/user-attachments/assets/429e19a1-4b30-461c-9a54-380654162333" height="70" style="vertical-align: baseline;" />
- disabled default ls alias (I prefer to set those myself, it also needs to  
  configurable instead of default)
- add clear on C-l

**Enjoy!**

---

# xelabash

![xelabash](images/base.png)

A few simple, no-nonsense, non-distracting additions to the standard bash prompt.

## Features

- Compact, minimalist, single-line prompt, featuring:
  - Red `$` (or `#`, if root) in prompt following an error
  - `user@hostname`, but only when in a remote session
  - Git branch and working copy dirty status, when in a Git repo
  - Active Kubernetes context and namespace
- "Better"-than-default autocomplete settings
- Not overly opinionated; designed to integrate with other settings and tools if desired

## Install and Setup

Works best with bash 4.4+. There are no dependencies to install.

To install, simply clone this repo and source `xela.bash` in your `.bash_profile`. (If `.bash_profile` doesn't work, try `.bashrc`.)

```bash
cd
git clone --depth=1 https://github.com/aelindeman/xelabash "${XDG_DATA_HOME:-~/.local/share}/xelabash"
echo 'source "${XDG_DATA_HOME:-~/.local/share}/xelabash/xela.bash"' >> .bash_profile
```

Xelabash will load configuration files from the `config.d/` folder in this repository, so you can fork this repo and add your own aliases, configs, functions, environment variables, or whatever else you need.

Git and Kubernetes prompt pieces are **opt-in.** Just set `GIT_PROMPT=true` and/or `KUBE_PROMPT=true` before you load Xelabash:

```bash
GIT_PROMPT=true
KUBE_PROMPT=true
source ~/.local/share/xelabash/xela.bash
```

Alternatively, if you don't want to always see them, use a tool like [direnv](https://github.com/direnv/direnv) to set those environment variables conditionally based on your working directory.

## More pictures

- Full `cwd`

  ![dir](images/dir.png)

- Git status and branch

  ![git](images/git.png)

- Kubernetes context (and namespace, if set)

  ![kube](images/kube.png)

- Last process exit status

  ![exit](images/exit.png)

- Username and hostname, when connected via `ssh`

  ![ssh](images/ssh.png)

- ...and they all work in combination with each other

  ![combo](images/combo.png)
