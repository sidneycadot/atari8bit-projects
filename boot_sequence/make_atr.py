#! /usr/bin/env python3

import argparse
import struct

def make_atr_header(disksize):

    PARAGRAPH_SIZE = 16

    assert disksize % PARAGRAPH_SIZE == 0
    num_paragraphs = disksize // PARAGRAPH_SIZE

    h1_magic             = 0x0296
    h2_num_paragraphs_lo = num_paragraphs  % 0x10000
    h3_sector_size       = 128
    h4_num_paragraphs_hi = num_paragraphs // 0x10000
    h5_dummy1            = 0
    h6_dummy2            = 0
    h7_dummy3            = 0
    h8_dummy4            = 0

    atr_header = struct.pack(
            "<HHHHHHHH",
            h1_magic,
            h2_num_paragraphs_lo,
            h3_sector_size,
            h4_num_paragraphs_hi,
            h5_dummy1,
            h6_dummy2,
            h7_dummy3,
            h8_dummy4
        )

    return atr_header

def read_file(filename):
    with open(filename, "rb") as f:
        data = f.read()
    print("Read '{}' ({} bytes).".format(filename, len(data)))
    return data

def write_file(filename, data):
    with open(filename, "wb") as f:
        f.write(data)
        print("Wrote '{}' ({} bytes).".format(filename, len(data)))

def fillout(data, sector_size):
    original_size = len(data)
    adjusted_size = original_size + -original_size % sector_size
    return data.ljust(adjusted_size, b'\x00')


def make_atr(filenames_in, atr_filename):

    disksize = 720 * 128

    # Read the input files, fill them out to the disk sector size, and concatenate them.
    disk_image = fillout(b''.join(fillout(read_file(filename[2:]), 128) if filename.startswith("f:") else read_file(filename) for filename in filenames_in.split(",")), disksize)

    atr_header = make_atr_header(disksize)

    atr_image = atr_header + disk_image

    write_file(atr_filename, atr_image)


def main():

    parser = argparse.ArgumentParser(description="Make Atari 8-bit ATR image from raw boot image.")
    parser.add_argument("filenames_in", help="input file(s). If more than one, separate them by commas. File names that are preceded be 'f:' are expanded to a multiple of 128 bytes by adding zeros.")
    parser.add_argument("filename_out", help="output file (ATR format)")

    args = parser.parse_args()

    make_atr(args.filenames_in, args.filename_out)


if __name__ == "__main__":
    main()
