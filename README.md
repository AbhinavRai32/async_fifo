Asynchronous FIFO

A parameterized asynchronous FIFO designed and verified in Verilog, built around gray-coded pointer synchronization for safe clock domain crossing (CDC), with a self-checking testbench driven by dual independent clocks.

Overview

This project implements a dual-clock-domain FIFO — write and read operate on completely independent, unrelated clocks — with:

Parameterized depth and data width
Gray-coded read/write pointers for safe multi-bit CDC transfer
Full/empty detection using the extra-MSB pointer trick, computed against synchronized (not raw) pointer values
Dedicated 2-flop synchronizers for both reset and pointer crossing, kept as separate reusable modules
Design Details

Parameters

verilog
parameter depth = 16,   // FIFO depth
parameter width = 8     // Data width

Why Gray Code
Binary pointers can have multiple bits change simultaneously on an increment (e.g. 011 → 100). Sampled across an unrelated clock domain, a multi-bit transition can be caught mid-change and produce a corrupted, non-adjacent value. Gray code guarantees exactly one bit changes per increment, so a value sampled mid-transition is always off by at most one count — never corrupted.

Reset Synchronization
A single external reset is synchronized independently into each clock domain via a dedicated 2-flop reset_sync module — asynchronous assert (immediate, for safety), synchronous deassert (clean release on a clock edge, avoiding a metastable release window).

Pointer Synchronization
Each domain's gray pointer is passed into the other domain through a 2-flop syncff_2 module before being used in full/empty comparison — giving any metastable sample a full clock period to resolve before it can propagate further.

Full/Empty Detection

Empty (read domain): rptr_gray == synchronized wptr_gray — direct equality
Full (write domain): top two MSBs of wptr_gray inverted relative to the synchronized rptr_gray, remaining bits equal — this distinguishes "wrapped exactly once more" from "caught up," which plain equality cannot
Verification Approach

The testbench uses a queue-based reference model rather than a fixed expected-sequence check:

An independent array + pointer pair (ref_mem, ref_wptr, ref_rptr) tracks pushes and pops
Legality of each push/pop is checked against the DUT's own full/empty outputs, not a separately-computed condition — this means the reference model automatically inherits the DUT's real CDC visibility latency instead of requiring it to be modeled by hand
Comparison happens on negedge rclk, after all posedge-triggered updates have settled, gated by a read_valid flag so only actual reads are checked

Stimulus
Two clocks (10ns / 7ns — deliberately unrelated periods) drive independent, concurrent, randomized write and read processes via fork...join, rather than sequential directed writes-then-reads, to genuinely exercise the CDC paths under realistic non-lockstep conditions.

Checks Performed
Data integrity: every popped value compared against the reference model's expected value
Full/empty legality: writes/reads only accepted when the DUT itself reports room/data available
Concurrent CDC stress: simultaneous, independently-timed writes and reads across unrelated clock domains
Running the Simulation (Vivado)
Add async_fifo.v and async_fifo_tb.v to a Vivado project
Set async_fifo_tb as the simulation top
Run Behavioral Simulation
Check the Tcl console / log for [PASS] / [FAIL] messages from the reference model checks
Known Limitations / Pending Work
No SystemVerilog assertions (SVA) yet — directed checks via the reference model are used instead
No functional coverage collection
No explicit pass/fail summary counters — results are logged per-check, not aggregated

