# bcfv

`bcfv` is a Bash frontend to checksum programs (SHA, Blake3, MD5) to calculate, update and verify checksums through directory tree. Inspired by Python based [cfv](https://github.com/cfv-project/cfv). 

## Operations

`bcfv` is very simple. It creates checksum (`.checksum.xxx`) files for each directory with files. The checksum file format is always the native file format of the underlying checksum program. The suffix of the checksum file varies by checksum algorithm (`.b3` for Blake3, `.sha256` for SHA-256, etc.).  

## Install

1. Copy `bcfv` to PATH and give it exec permissions

```
# example
cp bcfv /usr/local/bin
chmod a+rx /usr/local/bin/bcfv
```

2. Install required checksum programs:

* [Blake3](https://github.com/BLAKE3-team/BLAKE3) (default): `b3sum`
* MD5: `md5sum`
* SHA-256: `sha256sum`
* SHA-512: `sha512sum`

Most UNIX-like OS have `md5sum`, `sha256sum` and `sha512sum` installed by default. 

## Usage

```
Usage: bcfv [-hqdcu] [-b DIR] DIR [DIR1 ...]
        -h      Display help
        -q      Do not print checksums
        -c      Check existing checksums
        -u      Update changed checksums
        -d      Add date to previous checksum version
        -a ALGO Select checksum algorithm: b3, md5, sha256, sha512. Default is b3
        -b DIR  Base directory for the operations
By default, the program will *create* checksums
```
# Motivation

I wrote `bcfv` since my old trusted Python 2.7 based [cfv](https://github.com/cfv-project/cfv) stopped working as distros like Debian/Ubuntu moved to Python 3. [cfv](https://github.com/cfv-project/cfv) had been long dormant and unmaintained, so I decided to write the same functionality using [Bash](https://www.gnu.org/software/bash/) shell only hoping I would not need to touch the code again for the next 20 years :-) 

However, it seems the cfv project has been resurrected and a Python 3.x based version is about to come out. I have not made any performance benchmarking yet, but I believe `cfv` will outperform `bcfv`. 

Performance never was a priority for `bcfv`, but a reliable operation and an implementation that would require zero maintenance and had minimal dependencies. I also wanted to be able toe verify the checksums directly with the underlying checksum tools (`b3sum`, `sha256sum`, etc.)
