
The Atari 8-bit disk boot process
=================================

The boot sequence of the Atari 8-bit systems is documented in the Atari Operating Systems User's Manual.

A scan of this document can be downloaded here:

    https://ia804603.us.archive.org/19/items/AtariOperatingSystemUsersManualNovember1980/AtariOperatingSystemUsersManualNovember1980.pdf

The relevant sections:


section                                       doc_page                    pdf_page
===============================================================================================
 2. Functional organisation / Power up         15--16                      19--20
 7. System initialization                     109--112                    117--120
10. Program environment and initialization    141--                       153--

The disk boot process
=====================

Described in Section 10, page 143--144 (page 156--157 of PDF).

(1) The first disk sector is loaded at address $0400.
(2) Extract DFLAGS, DBSECT, load address, and DOSINI address from the 6-byte sector header.
(3) Move the sector to the load address specified in the header.
(4) Read remaining boot sectors at the right place.
(5) JSR to load address + 6. Carry bit of result will indicate success (C=0) or failuire (C=1).
(6) JSR indirectly to DOSINI, which was set from the 1st sector header.
(7) JMP indirectly through DOSVEC to transfer control to the application.

At soft reset ("warm start"), steps 6 and 7 are repeated.

DOSVEC, if set, should be set in step (5), i.e., the code directly following the header.
