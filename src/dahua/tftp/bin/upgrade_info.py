#!/usr/bin/env python
import zlib
import sys

with open(sys.argv[1], "rb") as cmdfile:
	data = cmdfile.read()

	magic = b"MagicString:c016dcd6-cdeb-45df-9fd0-e821bf0e1e62\n"
	crc = zlib.crc32(magic)
	crc = zlib.crc32(data, crc)

	output = b"CRC:" + str(crc).encode("ascii") + b'\n'
	output += magic
	output += data

	with open("upgrade_info_7db780a713a4.txt", "wb") as outfile:
		outfile.write(output)
