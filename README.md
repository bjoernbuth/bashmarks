### Bashmarks is a shell script that allows you to save and jump to commonly used directories. Now supports tab completion.

## Install

1. `git clone git@github.com:huyng/bashmarks.git`
2. `cd bashmarks`
3. `make install`
4. source **~/.local/bin/bashmarks.sh** from within your **~.bash\_profile** or **~/.bashrc** file

## Shell Commands

    s <bookmark_name> - Saves the current directory as "bookmark_name"
    g <bookmark_name> - Goes (cd) to the directory associated with "bookmark_name"
    p <bookmark_name> - Prints the directory associated with "bookmark_name"
    d <bookmark_name> - Deletes the bookmark
    l                 - Lists all available bookmarks

## Example Usage

    $ cd /var/www/
    $ s webfolder
    $ cd /usr/local/lib/
    $ s locallib
    $ l
    $ g web<tab>
    $ g webfolder

## Where Bashmarks are stored

All of your directory bookmarks are saved in a file called ".sdirs" in your HOME directory.

## Using several bookmarks files
- Create different files in ~/.local/bashmarks-favorites (or customize the path in the script)
- Customize the used aliases accoring to your needs in the script (currently the function bm
  is used for s

```text
    bm  info           info - show the current bookmarks and the bookmarks folder
    bm  i              info - show the current bookmarks and the bookmarks folder

    bm  switch file    switch to another bookmark file (calls bms name)
    bm  s file         switch to another bookmark file (calls bms name)

    bm  h              help
    bm help            show the source code of the function bm

    bms file           switch (s = switch), use another bookmark file
    bms                show the source code of the function bm
```

## Creators  (of bashmarks the original version)

* [Huy Nguyen](https://github.com/huyng)
* [Karthick Gururaj](https://github.com/karthick-gururaj)
