# albis

Artix Linux Bootstrapping Installation Script(s) is (are) shell script(s),
which aims to provide full system installation of Artix Linux distribution with easy configuration.

## Usage

### Execution

Download Artix Linux ISO from [official sources](https://artixlinux.org/download.php), boot in and execute following command.

**Note**: if you are not familiar with this process, you might want to search for some tutorials on how to prepare installation media
and how to boot from them.

```
curl https://raw.githubusercontent.com/bulirma/albis/master/launch.sh | sh
```

### Target

The script(s) has (have) been tested for Artix ISO for x86\_64 from 2022-07-13. There are several features or configuration posibilities,
which are available, but might not or does not work. Those are listed below.

- dotfiles installation
- launch script (working, but cause bugs with gum util i.e. filling input field with commands)
- efi boot (not tested)

## Testing

If you want to test first in [QEMU](https://qemu.org), you can change directory to `testing` and run:

```
make install
```

...assuming you have first downloaded the ISO file and move it to `testing/artix.iso`.
