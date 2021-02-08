![By ULHPC](https://img.shields.io/badge/by-ULHPC-blue.svg) [![github](https://img.shields.io/badge/git-github-lightgray.svg)](https://github.com/ULHPC/tools) [![Issues](https://img.shields.io/badge/issues-github-green.svg)](https://github.com/ULHPC/tools/issues)

         _    _ _      _    _ _____   _____   _______          _        _______ _                             _       __
        | |  | | |    | |  | |  __ \ / ____| |__   __|        | |      / / ____| |                           | |      \ \
        | |  | | |    | |__| | |__) | |         | | ___   ___ | |___  | | (___ | |_   _ _ __ _ __ ___     ___| |_ ___  | |
        | |  | | |    |  __  |  ___/| |         | |/ _ \ / _ \| / __| | |\___ \| | | | | '__| '_ ` _ \   / _ \ __/ __| | |
        | |__| | |____| |  | | |    | |____     | | (_) | (_) | \__ \ | |____) | | |_| | |  | | | | | | |  __/ |_ (__ _| |
         \____/|______|_|  |_|_|     \_____|    |_|\___/ \___/|_|___/ | |_____/|_|\__,_|_|  |_| |_| |_|  \___|\__\___(_) |
                                                                       \_\                                            /_/

       Copyright (c) 2020-2021 UL HPC Team <hpc-team@uni.lu>

Various HPC Tools and helper scripts/functions (slurm, ssh etc.)

```bash
.
├── Makefile      # GNU Makefile root configuration
├── README.md
├── VERSION       # /!\ DO NOT EDIT: store current version of the repository
└── slurm         # Slurm tools and utilities
    └── profile.d
        └── slurm.sh     # Slurm helpers, to be sourced
```

Similar project/resources:

* <https://github.com/dieterich-lab/slurm-tools>
* <https://github.com/OleHolmNielsen/Slurm_tools>





## Installation / Repository Setup

This repository is hosted on [Github](https://github.com/ULHPC/tools).
To clone this repository, proceed as follows (adapt accordingly):

```bash
$> mkdir -p ~/git/github.com/ULHPC/
$> cd ~/git/github.com/ULHPC/
$> git clone https://github.com/ULHPC/tools.git
```

**`/!\ IMPORTANT`**: Once cloned, initiate your local copy of the repository by running:

```bash
$> cd tools
$> make setup
```

This will initiate the [Git submodules of this repository](.gitmodules) and setup the [git flow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow) layout for this repository. Later on, you can update your local branches by running:

     $> make up

If upon pulling the repository, you end in a state where another collaborator have upgraded the Git submodules for this repository, you'll end in a dirty state (as reported by modifications within the `.submodules/` directory). In that case, just after the pull, you **have to run** `make up` to ensure consistency with regards the Git submodules:

Finally, you can upgrade the [Git submodules](.gitmodules) to the latest version by running:

    $> make upgrade    # OR: 'git submodule update'

## Issues / Feature request

You can submit bug / issues / feature request using the [`ULHPC/tools` Project Tracker](https://github.com/ULHPC/tools/issues)

## Misc.

### [Git-flow](https://github.com/petervanderdoes/gitflow-avh)

The Git branching model for this repository follows the guidelines of
[gitflow](http://nvie.com/posts/a-successful-git-branching-model/).
In particular, the central repository holds two main branches with an infinite lifetime:

* `production`: the *production-ready* branch
* `master`: the main branch where the latest developments interviene. This is the *default* branch you get when you clone the repository.

Thus you are more than encouraged to install the [git-flow](https://github.com/petervanderdoes/gitflow-avh) (AVH Edition, as the traditional one is no longer supported) extensions following the [installation procedures](https://github.com/petervanderdoes/gitflow-avh/wiki/Installation) to take full advantage of the proposed operations. The associated [bash completion](https://github.com/bobthecow/git-flow-completion) might interest you also.

### Releasing mechanism

The operation consisting of releasing a new version of this repository is automated by a set of tasks within the root `Makefile`.

In this context, a version number have the following format:

      <major>.<minor>.<patch>[-b<build>]

where:

* `< major >` corresponds to the major version number
* `< minor >` corresponds to the minor version number
* `< patch >` corresponds to the patching version number
* (eventually) `< build >` states the build number _i.e._ the total number of commits within the `master` branch.

Example: \`1.0.0-b28\`

The current version number is stored in the root file `VERSION`. __/!\ NEVER MAKE ANY MANUAL CHANGES TO THIS FILE__

For more information on the version, run:

     $> make versioninfo

If a new version number such be bumped, you simply have to run:

      $> make start_bump_{major,minor,patch}

This will start the release process for you using `git-flow`.
Once you have finished to commit your last changes, make the release effective by running:

      $> make release

It will finish the release using `git-flow`, create the appropriate tag in the `production` branch and merge all things the way they should be.

## Contributing

That's quite simple:

1. [Fork](https://help.github.com/articles/fork-a-repo/) it
2. Create your own feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new [Pull Request](https://help.github.com/articles/using-pull-requests/)
