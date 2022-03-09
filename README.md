# aur - a wrapper script to make using auracle easier

This is a wrapper for
[auracle](https://github.com/falconindy/auracle). It won't work
without it.

To use **aur**, you can source it from your `.bashrc` or `.zshrc`.
This script is intended to be compatible with both. If you see any
errors, make sure the equivalent command works with `auracle` and
file an issue.

When packages are built with `aur upgrade` or `aur build`, the
packages are built in the order that `auracle buildorder` says is
appropriate. Thus, `aur` includes reliable dependency checking.

## How to use this script

The command `aur` is added. In many cases it will just do the same
thing as `auracle`. The following cases are distinct:

`aur <command>`

 * `upgrade <names>`: checks the AUR for updates to the PKGBUILD,
 shows them to you in diff form, and asks what to do. You can merge
 the changes to your local repository and automatically build,
 reject the changes, or merge them without building. When `<names>`
 is missing, asks `auracle` for a list of AUR packages that need to
 be updated, and acts on those packages instead.

 * `build <names>`: without fetching new changes from the AUR,
 show any changes in the local git history since the last time the
 package was built, and asks you to approve them. For any packages
 you approve, the package will be built and installed. When 
 `<names>` is missing, checks which packages have been changed since
 the last time the package was built, and acts on those packages
 instead.

 * `clean <names>`: removes all build files (everything not tracked
 by git) in the local repository for the package(s). If `<names>` is
 not provided, does this for every package. This is done with an
 interactive prompt via `git clean -fidx`.

 * `outdated`: calls `auracle outdated`, then checks whether any
 packages have changes already merged to the local repository that
 haven't been built yet. This makes it easier to keep track of which
 packages are ready to be built, and which still need review. You
 can end up with locally merged changes by explicitly requesting
 this during an `upgrade` or by running `aur update`.

 * `clone`: calls `auracle clone`, but forces auracle to change
 directories to your AUR cache first, and clones recursively.

 * `update`: calls `auracle update`, but forces auracle to change
 directories to your AUR cache first, and updates recursive
 dependencies.

 * `help`: calls `auracle -h` to show help for auracle.

## Why use this script?

Auracle is awesome, but it doesn't do everything. In particular, it
doesn't help you by showing diffs for PKGBUILD updates, and it can't
build or install packages for you. This script does both and more.

Why not just use one of the big complicated AUR helpers instead? You
can! I personally have not found one that I really like. To mention
only the ones on the Wiki that have diff viewing:

 * rua: as with many ~~nodejs~~ Rust applications, uses an unholy
 number of dependencies. Also, the amount of prompting (with no
 default options available) is unreasonable. Printing the diff by
 default is reasonable behavior. Accepting the changes after the
 diff has been viewed is also. rua does neither.

 * aurutils: I don't really like the model of having my own local
 repository, so this isn't for me. I haven't looked at it in much
 detail beyond that.

 * yay: I used to use this, but diff view has been broken for years
 now with no fix in sight. Specifically, the diffs for each changed
 file are printed individually, so if each one fits on your screen,
 you don't get a pager. This makes it very hard to review diffs.

A few that I haven't looked at in much detail yet:

 * paru: Rust, so also an absurd number of dependencies. I don't
 really need or want a pacman wrapper. Playing around with it for a
 while, I found the interface rather unintuitive.

 * pacaur: a slightly more complicated shell wrapper around auracle.
 Given that my needs are rather simple and I don't need a pacman
 wrapper at all, I didn't look at this one more closely.

There are others, but honestly since my needs are pretty simple, I
think it's probably just easier to maintain 100 lines or so of shell.

## Contributing

Reasonable pull requests are welcomed. Please don't try to add
pacman wrapping. Any changes you make should be run through 
`shellcheck` before submission.
