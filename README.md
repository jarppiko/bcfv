# cfv

cfv is a Bash frontend to checksum programs (SHA, Blake3, MD5) to calculate, update and verify checksums through directory tree. Inspired by (legacy) Python 2.7 based [cfv](https://github.com/cfv-project/cfv). 

## Install

1. Copy `cfv` to PATH and give it exec permissions

```
# example
cp cfv /usr/local/bin
chmod a+rx /usr/local/bin/cfv
```

2. Install required checksum programs:

* [Blake3](https://github.com/BLAKE3-team/BLAKE3) (default): `b3sum`
* MD5: `md5sum`
* SHA-256: `sha256sum`
* SHA-512: `sha512sum`

Most UNIX-like OS have `md5sum`, `sha256sum` and `sha512sum` by default. 

## Usage

```
Usage: cfv [-hqdcu] [-b DIR] DIR [DIR1 ...]
        -h      Display help
        -q      Do not print checksums
        -c      Check existing checksums
        -u      Update changed checksums
        -d      Add date to previous checksum version
        -a ALGO Select checksum algorithm: b3, md5, sha256, sha512. Default is b3
        -b DIR  Base directory for the operations
By default, the program will *create* checksums
```
