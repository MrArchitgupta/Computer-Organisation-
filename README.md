# Computer Organisation

A comprehensive repository demonstrating advanced computer architecture concepts through FPGA and processor design implementations in Verilog.

## Project Overview

This repository contains educational implementations of:

### 1. **MIPS Processor Implementations**
Two iterations of MIPS processor design, progressively incorporating advanced features.

#### MIPS_Processor1
- **Computer.v**: Top-level module orchestrating the processor and memory subsystem
  - Manages instruction and data memory access
  - Tracks total cycles and processor execution cycles
  - Provides register outputs for verification and debugging
  - Implements cycle counting with separate storage and execution phases

#### MIPS_Processor2
- Enhanced version with additional optimizations and features

**Key Features:**
- Instruction memory management
- Cycle-accurate performance monitoring
- Register bank exposure for debugging
- Clean separation of storage phase and execution phase

### 2. **FPGA as an Accelerator**
Demonstrates FPGA acceleration of graph algorithms using matrix operations.

#### graph.v
- **Purpose**: Graph path finding using matrix-based algorithms
- **Algorithm**: Implements iterative matrix multiplication to find paths between vertices
- **Key Components**:
  - Adjacency matrix input (32×32 register array)
  - Transposed adjacency matrix for optimized computation
  - Finite State Machine (FSM) for orchestrating computation stages
  - Parallel processing of matrix operations across 4 states (rows 0-7, 8-15, 16-23, 24-31)
  
- **Computation Flow**:
  1. State 0: Accept adjacency matrix via serial input
  2. State 1: Initialize result matrix B from adjacency matrix A
  3. States 2-5: Parallel matrix multiplication (C = B × A_transposed) split across 4 cycles
  4. State 6: Update B with results and loop for next iteration
  5. State 7: Signal completion
  6. State 8: Count ARM simulation cycles

- **Performance Metrics**: ARM cycle counting for performance comparison

#### matrix_tb.v
- **TestBench**: Comprehensive test for matrix-vector multiplication acceleration
- **Test Vectors**:
  - Matrix M: 16×16 with values (row - col) - tests positive, negative, and zero values
  - Vector x: 16-element with alternating 1 and -1 values
  - Expected result: All output values should be 8
- **Verification**: 
  - FPGA computation results
  - ARM simulation cycle counting
  - Performance comparison metrics

**Key Features:**
- Full 16×16 matrix-vector multiplication
- 2's complement arithmetic for signed operations
- Cycle-accurate performance measurement
- Comparative analysis between FPGA and ARM execution

## Technical Highlights

### Architecture Patterns
- **Finite State Machines (FSM)**: Used for coordinating complex multi-stage computations
- **Parallel Processing**: Matrix operations distributed across multiple cycles
- **Register Arrays**: Efficient storage and manipulation of matrix data
- **Cycle Counting**: Accurate performance profiling

### Design Principles
- Clear separation of concerns (compute, control, I/O)
- Scalable architecture (32×32 matrices, extensible to larger dimensions)
- Performance metrics built into the design
- Comprehensive testbenches for validation

## Applications

This repository demonstrates:
- Custom processor design for embedded systems
- FPGA-based acceleration of computationally intensive algorithms
- Performance optimization techniques
- Digital design best practices in Verilog

## Getting Started

1. Review `MIPS_Processor1/Computer.v` for basic processor architecture
2. Study `FPGA as an Accelerator/graph.v` for advanced FSM and parallel processing patterns
3. Run testbenches (e.g., `matrix_tb.v`) to understand simulation and verification flows

## Tools Required
- Verilog simulator (Xilinx ISE, Vivado, or ModelSim)
- Understanding of:
  - Digital logic fundamentals
  - MIPS instruction set architecture
  - Matrix algorithms
  - Finite state machines

---

**Repository Structure:**
```
Computer-Organisation-/
├── MIPS_Processor1/          # Single-cycle MIPS processor
├── MIPS_Processor2/          # Enhanced MIPS processor
├── FPGA as an Accelerator/   # Graph algorithm acceleration
└── README.md                 # This file
```
