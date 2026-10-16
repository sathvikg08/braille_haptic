#!/usr/bin/env python3
"""
Braille-to-text assistive system (software layer).

  Input handler  ->  Verilog decoder (Icarus)  ->  text buffer  ->  display / speech

Type braille cells as dot numbers, e.g.  "125 15 123 123 135"  ->  hello
  0 = space     back = delete last char     clear = empty buffer
  speak = read text aloud (needs: pip install pyttsx3)     quit = exit
"""
import subprocess, sys, os, tempfile, shutil

HERE = os.path.dirname(os.path.abspath(__file__))


# ---------- Input handler: "125" -> 6-bit pattern ----------
def dots_to_bits(group: str) -> str:
    """'14' -> '001001'  (bit order: dot6 ... dot1)"""
    if group != "0" and (not group.isdigit() or any(c not in "123456" for c in group)):
        raise ValueError(f"bad dot group '{group}' (use digits 1-6, or 0 for space)")
    on = set() if group == "0" else set(group)
    return "".join("1" if str(d) in on else "0" for d in range(6, 0, -1))


# ---------- Simulation interface: run the Verilog decoder ----------
def run_decoder(patterns):
    """patterns: list of 6-char bit strings -> list of (char, valid)."""
    if not patterns:
        return []
    with tempfile.TemporaryDirectory() as tmp:
        with open(os.path.join(tmp, "input.mem"), "w") as f:
            f.write("\n".join(patterns) + "\n")
        sim = os.path.join(tmp, "sim.vvp")
        subprocess.run(
            ["iverilog", "-o", sim,
             os.path.join(HERE, "braille_decoder.v"), os.path.join(HERE, "tb_braille.v")],
            check=True)
        out = subprocess.run(["vvp", sim, f"+N={len(patterns)}"],
                             cwd=tmp, capture_output=True, text=True, check=True).stdout
    results = []
    for line in out.splitlines():
        if line.startswith("RESULT"):
            _, code, valid = line.split()
            results.append((chr(int(code)), valid == "1"))
    return results


# ---------- Text processing: buffer with space / backspace / clear ----------
class TextBuffer:
    def __init__(self):
        self.text = ""

    def add(self, ch):   self.text += ch
    def back(self):      self.text = self.text[:-1]
    def clear(self):     self.text = ""


# ---------- Output: display + optional text-to-speech ----------
def speak(text):
    try:
        import pyttsx3
        engine = pyttsx3.init()
        engine.say(text)
        engine.runAndWait()
    except ImportError:
        print("  (TTS not installed: pip install pyttsx3)")


def selftest():
    letters = {'a':'1','b':'12','c':'14','d':'145','e':'15','f':'124','g':'1245','h':'125',
               'i':'24','j':'245','k':'13','l':'123','m':'134','n':'1345','o':'135','p':'1234',
               'q':'12345','r':'1235','s':'234','t':'2345','u':'136','v':'1236','w':'2456',
               'x':'1346','y':'13456','z':'1356'}
    res = run_decoder([dots_to_bits(d) for d in letters.values()])
    bad = [(k, r) for k, r in zip(letters, res) if r != (k, True)]
    print("PASS: all 26 letters decode correctly" if not bad else f"FAIL: {bad}")
    return not bad


def main():
    if not shutil.which("iverilog"):
        sys.exit("Install Icarus Verilog first (e.g. sudo apt install iverilog)")
    if "--selftest" in sys.argv:
        sys.exit(0 if selftest() else 1)

    buf = TextBuffer()
    print(__doc__)
    while True:
        try:
            line = input("braille> ").strip().lower()
        except (EOFError, KeyboardInterrupt):
            break
        if line == "quit":  break
        if line == "clear": buf.clear()
        elif line == "back": buf.back()
        elif line == "speak": speak(buf.text)
        elif line:
            try:
                groups = line.split()
                results = run_decoder([dots_to_bits(g) for g in groups])
            except ValueError as e:
                print("  ", e); continue
            for g, (ch, ok) in zip(groups, results):
                if ok: buf.add(ch)
                else:  print(f"   dots '{g}' not recognised")
        print(f"  text: \"{buf.text}\"")


if __name__ == "__main__":
    main()
