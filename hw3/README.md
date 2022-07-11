## Task:

Parašyti dalinį disasemblerį.
Apdoroti komandas MOV,OUT, NOT, RCR, XLAT.

Write a partial disassembler.
Process commands MOV, OUT, NOT, RCR, XLAT.

## How to run disassembler?
First of all, you should make a .com file.

```
    tasm src.asm
    tlink /t src
```
Now, you can compile and run disassember.

```
    tasm hw3.asm
    tlink /v hw3
    hw3 src.com res.txt
```
