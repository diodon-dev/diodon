# Diodon (Enhanced Edition)

A high-performance GTK+ clipboard manager — forked from [diodon-dev/diodon](https://github.com/diodon-dev/diodon) with major image handling improvements.

## What's New in This Version

- **3× larger image thumbnails** — 200×150 previews with contain-fit scaling, centered in the menu
- **Instant 4K image paste** — lazy clipboard serving via `set_with_owner()` eliminates desktop freezes
- **90% less memory** — single-slot PNG cache (~10 MB) replaces unbounded pixbuf storage (was 200+ MB)
- **No CPU spikes** — cached PNG bytes served directly to apps requesting `image/png`, zero re-encoding
- **Correct paste-from-history** — each item retains its own PNG data, no more stale image bugs
- **Wider text labels** — 100-char labels with 4-line word wrapping

See [IMPLEMENTATION.md](IMPLEMENTATION.md) for the full technical architecture and lifecycle documentation.

## Installing

For Ubuntu based distributes there is an official [stable PPA](https://launchpad.net/~diodon-team/+archive/stable).

    sudo add-apt-repository ppa:diodon-team/stable
    sudo apt-get update
    sudo apt-get install -y diodon


To install Diodon on other systems download a release tarball from [launchpad](https://launchpad.net/diodon/+download).

## Building

Diodon uses the [Meson](https://mesonbuild.com/) build system.

    git clone https://github.com/diodon-dev/diodon.git && cd diodon
    meson builddir && cd builddir
    ninja
    ninja test
    sudo ninja install
    # only needed after the first ninja install
    sudo ldconfig

The unity scope needs to be explicitly enabled if you want to build it

    meson configure -Denable-unity-scope=true

On distributions which do not provide packages for application-indicator
building of the indicator can be disabled by adjusting builddir creation command:

    meson builddir -Ddisable-indicator-plugin=true && cd builddir

For uninstalling type this:

    sudo ninja uninstall

## Plugins

If you would like to write your own Diodon plugin please refer to [the original blog post](http://esite.ch/2011/10/19/writing-a-plugin-for-diodon/). Feel free to add your own plugins to the list below.

|  Plugin                                                  | Description                                        |
| -------------------------------------------------------- | -------------------------------------------------- |
| [Features](https://github.com/RedHatter/diodon-plugins)  | Additional features for the diodon menu.           |
| [Numbers](https://github.com/RedHatter/diodon-plugins)   | Number clipboard menu items.                       |
| [Pop Item](https://github.com/RedHatter/diodon-plugins)  | Pastes and then removes the active clipboard item. |
| [Paste All](https://github.com/RedHatter/diodon-plugins) | Paste all recent items at once                     |
| [Edit](https://github.com/RedHatter/diodon-plugins)      | Prompts to edit the active item.                   |

## Store clipoard items in memory

Diodon uses [Zeitgeist](https://gitlab.freedesktop.org/zeitgeist/zeitgeist) to store clipboard items. Per default Zeitgeist persists all events in a database on the hard disc so it is available after a reboot. If you want to store it to memory you need to set environment variable `ZEITGEIST_DATABASE_PATH` to `:memory:` with a command like the following (might differ depending on your setup):

    echo "ZEITGEIST_DATABASE_PATH=:memory:" >> ~/.pam_environment

## Support

Take part in the discussion or report a bug on the [launchpad](https://bugs.launchpad.net/diodon) page.
