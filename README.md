# Braille Haptic Reader

A braille-to-text system with two parts:

1. **Hardware design (Verilog)**: a combinational decoder that turns a 6-dot braille cell into an 8-bit ASCII character, simulated with Icarus Verilog and driven by a small Python app.
2. **Phone app (HTML/JavaScript)**: a touch interface where you *feel* braille dots as vibrations, type braille, and convert text back into braille.

The phone app uses the same dot-to-letter table and the same bit order as the Verilog decoder.

---

## Project structure

```
.
├── README.md
├── braille_haptic.html        # Phone app (single file, no install)
└── braille_decoder/
    ├── braille_decoder.v      # Verilog RTL: 6-bit dots -> ASCII
    ├── tb_braille.v           # Testbench driven by the Python app
    └── braille_app.py         # Python app: input, simulation, text buffer, speech
```

---

## How it works

```
Python app (braille_app.py)
  "125 15 123"  ->  6-bit patterns  ->  Verilog decoder (Icarus)  ->  ASCII  ->  text buffer  ->  display / speech
```

### Dot numbering and bit order

A braille cell has six dots:

```
 1  4
 2  5
 3  6
```

The decoder input is `dots[5:0] = {dot6, dot5, dot4, dot3, dot2, dot1}`, so dot 1 is bit 0.

| Letter | Dots | `dots[5:0]` | ASCII |
|--------|------|-------------|-------|
| a | 1 | `000001` | 0x61 |
| b | 12 | `000011` | 0x62 |
| c | 14 | `001001` | 0x63 |
| d | 145 | `011001` | 0x64 |
| space | none | `000000` | 0x20 |

The decoder covers **a to z and space**. It outputs:
- `ascii_out[7:0]`: the character code
- `valid`: `1` if the pattern is recognised, `0` otherwise (output is `?`)

---

## Part 1: Verilog decoder and Python app

### Requirements
- Python 3.8+
- Icarus Verilog (`iverilog` and `vvp`)
  - Ubuntu/Debian: `sudo apt install iverilog`
  - macOS: `brew install icarus-verilog`
  - Windows: install from https://bleyer.org/icarus/
- Optional, for speech: `pip install pyttsx3`

### Run it
Keep the three files in `braille_decoder/` together, then:

```bash
cd braille_decoder
python3 braille_app.py --selftest   # checks all 26 letters through the Verilog decoder
python3 braille_app.py              # interactive mode
```

### Interactive commands
Type braille cells as dot numbers separated by spaces:

```
braille> 125 15 123 123 135 0 2456 135 1235 123 145
  text: "hello world"
```

| Input | Action |
|-------|--------|
| `1`, `12`, `145` ... | Dot numbers for one cell |
| `0` | Space |
| `back` | Delete last character |
| `clear` | Empty the text buffer |
| `speak` | Read the text aloud (needs `pyttsx3`) |
| `quit` | Exit |

### Run the testbench by hand (optional)
The testbench reads patterns from `input.mem` and prints one result per line:

```bash
printf "000001\n000011\n001001\n" > input.mem
iverilog -o sim braille_decoder.v tb_braille.v
vvp sim +N=3
# RESULT 97 1
# RESULT 98 1
# RESULT 99 1
```

---

## Part 2: Phone app (`braille_haptic.html`)

A single self-contained file. No server, no install, no internet needed.

### Modes

| Mode | What it does |
|------|--------------|
| **Feel** | Hides a random letter. Slide a finger over the six dots; raised dots buzz. Tap **Reveal** to check, **Next letter** for another. |
| **Type** | Tap dots to raise them, then **Add** to decode the pattern into a letter. Also Space, Back, Clear and Speak. |
| **Text → Braille** | Type a word, see each letter as a braille cell. Tap a letter to feel it in the cell, **Play letter** to feel it as a vibration pattern, or **Play all** for the whole word. |

In Text → Braille playback, each letter is six time slots (dot 1 to dot 6, 150 ms each). A raised dot gives a short buzz and an empty dot gives silence.

### Run it on Android (recommended)
1. Copy `braille_haptic.html` to your phone.
2. Open **Chrome** and go to `file:///sdcard/Download/braille_haptic.html` (or tap the file in the Files app and choose Chrome).
3. Tap **Test buzz**. Then tap **Haptic check**: you should feel a short, a medium and a long buzz.

### Run it on iPhone (limited)
iPhones have no web vibration API. The app uses a Safari workaround (a haptic tick from a hidden toggle switch, iOS 17.4+):
- Tapping works best. Sliding across dots and **Play all** may buzz only partly or not at all.
- Turn on **Sound beeps** as a backup.
- Needs Safari, System Haptics on (Settings > Sounds & Haptics) and Low Power Mode off.
- For reliable continuous haptics on iPhone, a native app (Swift, Core Haptics) is needed.

### Troubleshooting vibration (Android)
- Open the file directly in **Chrome**, not inside another app's viewer, which may block vibration.
- Turn off **Battery Saver** and make sure touch/media vibration intensity is not off (on Samsung, check the separate vibration sliders).
- Read the line under the text box. It shows the dot detected and `vibrate() returned: true/false`. `false` means the browser is blocking vibration.
- If **Haptic check** only gives the long buzz, your phone ignores very short pulses.

---

## Customising

| To change | Where |
|-----------|-------|
| Add letters, digits or punctuation | `case` table in `braille_decoder.v`, the `MAP` table in `braille_haptic.html`, and the `letters` table in `braille_app.py --selftest` |
| Buzz length on a raised dot (Feel mode) | `vib(1000)` in the `slide()` function of `braille_haptic.html` |
| Playback speed of a letter | `patternFor()` (slot timing) and `t+=1500` in `play()` |
| Tap feedback in Type mode | `vib(120)` and `vib([70,60,70])` in the grid `click` handler |

---

## Notes and limitations

- Letters a to z and space only. Numbers, capitals and punctuation are not implemented.
- 
-Where Verilog is used: the desktop part. When you run braille_app.py, it writes your dot patterns to a file, compiles braille_decoder.v and tb_braille.v with Icarus Verilog, runs the simulation, and reads the ASCII results back. Every letter you type goes through the Verilog decoder, and the self-test I ran confirmed all 26 letters decode correctly that way.
-Phone uses Javascript copy of the same  verilog code as we cant run verilog on the phone
- gem5 is not used in this project. It simulates CPUs and memory systems, not RTL, so it isn't needed for the decoder.
- iPhone haptics are best-effort and untested on real devices.
