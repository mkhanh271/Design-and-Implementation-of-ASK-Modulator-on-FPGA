# Design-and-Implementation-of-ASK-Modulator-on-FPGA

> Implementation of an **Amplitude Shift Keying (ASK / OOK) modulator** on the **Intel DE10-Lite FPGA** (MAX10) using Verilog. The carrier is generated via a **Direct Digital Synthesis (DDS)** phase accumulator and a 256-entry sine LUT. Verified via **ModelSim simulation** and **MATLAB software cross-validation**.

---
## This is my group project, everything is good to run so dont be afraid :)) 
## 📋 Table of Contents

- [Overview](#overview)
- [How It Works](#how-it-works)
- [Project Structure](#project-structure)
- [Signal Parameters](#signal-parameters)
- [Hardware: DE10-Lite Pin Mapping](#hardware-de10-lite-pin-mapping)
- [Simulation: ModelSim](#simulation-modelsim)
- [Verification: MATLAB](#verification-matlab)
- [References](#references)

---

## Overview

**ASK (Amplitude Shift Keying)** modulates a digital data stream onto a carrier by switching the carrier amplitude ON or OFF — this specific variant is known as **OOK (On-Off Keying)**:

```
data = 1  →  ASK output = sine wave (carrier ON)
data = 0  →  ASK output = 0        (carrier OFF)
```

The carrier sine wave is produced entirely in hardware using a **Direct Digital Synthesis (DDS)** engine — a 32-bit phase accumulator incremented every clock cycle, whose upper 8 bits index into a 256-entry pre-computed sine LUT.

| Property | Value |
|---|---|
| FPGA Board | Intel DE10-Lite (MAX10) |
| Clock | 50 MHz (`MAX10_CLK1_50`) |
| Modulation | ASK / OOK |
| Carrier Generation | DDS (phase accumulator + sine LUT) |
| Carrier Frequency | ≈ 1.5625 MHz |
| Output width | 16-bit signed |
| LUT size | 256 entries × 16-bit |

---

## How It Works

### 1. Direct Digital Synthesis (DDS)

```
┌─────────────────────────────────────────────────────┐
│                  ASK_on_FPGA.v                      │
│                                                     │
│  clock ──►  [ 32-bit Phase Accumulator ]            │
│                  + increment each cycle             │
│                        │                           │
│              accumulator[31:24] + phase             │
│                        │  (8-bit address)          │
│                        ▼                           │
│              [ 256-entry Sine LUT ]  ──► sine[15:0] │
│                    Song_sin.v                       │
│                        │                           │
│  data ──────► [ OOK Gate: data ? sine : 0 ]        │
│                        │                           │
│                        ▼                           │
│                    ASK[15:0]                        │
└─────────────────────────────────────────────────────┘
```

**Carrier frequency formula:**

$$f_{carrier} = \frac{increment}{2^{32}} \times f_{clk} = \frac{\texttt{0x08000000}}{2^{32}} \times 50\,\text{MHz} \approx 1.5625\,\text{MHz}$$

### 2. OOK Modulation

```verilog
ASK <= data ? sine : 16'sd0;
```

When `data = 1`, the ASK output follows the sine wave. When `data = 0`, the output is forced to zero — producing the characteristic OOK envelope seen in simulation.

### 3. Phase Offset

The 8-bit `phase` input adds a constant phase offset to the sine lookup address, allowing phase adjustment without changing the carrier frequency:

```verilog
.address(accumulator[31:24] + phase)
```

---

## Project Structure

```
.
├── ASK_on_FPGA.v        # Core: DDS phase accumulator + 256-entry sine LUT + OOK gate
├── DE10_Lite_Top.v      # FPGA top-level: maps clock, KEY, SW, LEDR to ASK core
├── test_ASK.v           # ModelSim testbench: data pattern [1,0,1,0,1] × 2000ns
├── ASK_matlab.m         # MATLAB software simulation for cross-validation
└── README.md
```

| File | Role |
|---|---|
| `ASK_on_FPGA.v` | DDS engine + `Song_sin` module (sine LUT + OOK logic) |
| `DE10_Lite_Top.v` | Top-level wrapper for DE10-Lite board |
| `test_ASK.v` | Functional testbench: 50 MHz clock, data pattern, waveform stimulus |
| `ASK_matlab.m` | MATLAB reference model matching Verilog parameters exactly |

---

## Signal Parameters

### Phase Accumulator

| Parameter | Value | Description |
|---|---|---|
| `increment` | `0x08000000` | Phase step per clock cycle |
| Accumulator width | 32 bits | Full phase resolution |
| Address bits | `[31:24]` | Top 8 bits → 256 LUT entries |
| `phase` offset | 8-bit input | Constant phase shift |

### Carrier Frequency Calculation

```
f_carrier = (0x08000000 / 2^32) × 50 MHz
          = (134,217,728 / 4,294,967,296) × 50,000,000
          ≈ 1.5625 MHz
```

Carrier period ≈ **640 ns** → ~3 full cycles visible in each 2000 ns data window.

### Data Timing (Testbench)

```
t=0      ns : reset released
t=150    ns : data = 1  (carrier ON,  2000 ns)
t=2150   ns : data = 0  (carrier OFF, 2000 ns)
t=4150   ns : data = 1  (carrier ON,  2000 ns)
t=6150   ns : data = 0  (carrier OFF, 2000 ns)
t=8150   ns : data = 1  (carrier ON,  2000 ns)
t=10150  ns : $stop
```

---

## Hardware: DE10-Lite Pin Mapping

| FPGA Pin | Signal | Function |
|---|---|---|
| `MAX10_CLK1_50` | `clock` | 50 MHz system clock |
| `KEY[0]` | `reset` | Active LOW (inverted → active high reset) |
| `SW[0]` | `data` | Data input: 1 = carrier ON, 0 = carrier OFF |
| `LEDR[9:0]` | `ASK_out[15:6]` | Top 10 bits of ASK output mapped to LEDs |

The LED mapping `LEDR = ASK_out[15:6]` provides a visual indicator — LEDs light up when the carrier is active (`data = 1`) and go dark when the carrier is off (`data = 0`), giving a direct hardware demonstration of OOK modulation.

---

## Simulation: ModelSim

### Running the Simulation

```tcl
# In ModelSim console

# 1. Compile
vlog ASK_on_FPGA.v test_ASK.v

# 2. Simulate
vsim test_ASK

# 3. Add signals and run
add wave -r /*
run -all
```

### Waveforms to Observe

Add these signals to the wave window:

| Signal | Description |
|---|---|
| `clk_50` | 50 MHz clock |
| `reset` | Reset pulse at startup |
| `data` | Digital modulating signal [1,0,1,0,1] |
| `phase` | Phase offset (0 in testbench) |
| `sine[15:0]` | Raw carrier sine wave (always running) |
| `ASK[15:0]` | Modulated output (sine when data=1, zero when data=0) |
| `index` | Clock cycle counter |

### Expected Results

- **`sine`**: Continuous sinusoidal wave at ~1.5625 MHz regardless of data
- **`ASK`**: Sine wave present when `data=1`; flat zero when `data=0`
- Pattern clearly shows OOK envelope: ON → OFF → ON → OFF → ON

---

## Verification: MATLAB

`ASK_matlab.m` is a software reference model that replicates the Verilog hardware behavior exactly, using the same parameters.

### Parameters matched to hardware

```matlab
f_clk     = 50e6;           % 50 MHz clock
increment = 0x08000000;     % Same as testbench
f_carrier = (increment / 2^32) * f_clk  % → 1.5625 MHz
t_bit     = 2000e-9;        % 2000 ns per data bit
```

### Data pattern

```
[1, 0, 1, 0, 1]  — same sequence as testbench
```

### Output Plots

The MATLAB script produces a **3-panel figure**:

| Panel | Content |
|---|---|
| Top | Input data signal (digital, [1,0,1,0,1] over 10 μs) |
| Middle | Carrier signal (1.5625 MHz sine wave, continuous) |
| Bottom | ASK modulated output (OOK: carrier gated by data) |

The MATLAB output visually matches the ModelSim waveform, confirming the hardware implementation is correct.

---

## Simulation Results

### ModelSim — data = 0 (carrier OFF)
The `ASK[15:0]` output is flat zero while `sine[15:0]` continues running internally.

### ModelSim — data = 1 (carrier ON)
Both `ASK[15:0]` and `sine[15:0]` show the same sine waveform, confirming the OOK gate is working correctly.

### ModelSim — Full OOK Pattern
The complete [1,0,1,0,1] data sequence shows the characteristic ASK envelope: alternating bursts of sinusoidal carrier and silent intervals.

---

## References

- [Intel DE10-Lite User Manual](https://www.intel.com/content/www/us/en/developer/topic-technology/fpga/development-kits/de10-lite-board.html)
- Proakis, J.G. & Salehi, M. — *Digital Communications*, 5th ed., McGraw-Hill, 2008
- Vankka, J. — *Direct Digital Synthesizers*, Springer, 2001
- [Direct Digital Synthesis — Analog Devices Tutorial](https://www.analog.com/en/design-notes/all-about-direct-digital-synthesis.html)

---

## License

MIT License — see [LICENSE](LICENSE) for details.
