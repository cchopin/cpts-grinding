# 00 - Bonus (hors roadmap CPTS)

Cours supplementaires etudies en parallele de la certification CPTS.

## Cours

| # | Module | Statut |
|---|--------|--------|
| 1 | [Intro to Assembly Language](assembly/intro-to-assembly-language.md) | [x] |
| 2 | [Shellcoding](assembly/shellcoding.md) | [x] |
| 3 | [Shellcodes Reference](assembly/shellcodes-reference.md) | [x] |

## Boxes / Challenges recommandes

### Shellcoding & Binary Exploitation

| # | Box / Challenge | Plateforme | Type | Difficulte | Statut |
|---|----------------|------------|------|------------|--------|
| 1 | [Safe](https://app.hackthebox.com/machines/Safe) | HTB Machine | ROP + shellcode | Easy | [ ] |
| 2 | [October](https://app.hackthebox.com/machines/October) | HTB Machine | BOF Linux | Easy | [ ] |
| 3 | [Ellingson](https://app.hackthebox.com/machines/Ellingson) | HTB Machine | BOF + ROP Linux | Hard | [ ] |
| 4 | [Rope](https://app.hackthebox.com/machines/Rope) | HTB Machine | Exploitation binaire | Insane | [ ] |
| 5 | [Challenges Pwn (Easy)](https://app.hackthebox.com/challenges?category=pwn&difficulty=easy) | HTB Challenges | Injection shellcode | Easy | [ ] |
| 6 | [Challenges Pwn (Medium)](https://app.hackthebox.com/challenges?category=pwn&difficulty=medium) | HTB Challenges | Shellcode + contraintes | Medium | [ ] |

### Plateformes externes

| # | Plateforme | URL | Description |
|---|-----------|-----|-------------|
| 1 | pwnable.kr | http://pwnable.kr/ | Challenges shellcoding/exploitation |
| 2 | pwnable.tw | https://pwnable.tw/ | Challenges avances |
| 3 | Exploit Education | https://exploit.education/ | VMs Phoenix/Protostar/Fusion |
| 4 | ROP Emporium | https://ropemporium.com/ | Challenges ROP progressifs |
| 5 | Nightmare | https://guyinatuxedo.github.io/ | Cours/challenges pwn par difficulte |

## Ordre recommande

1. Intro to Assembly Language (theorie ASM)
2. Shellcoding (workflow + techniques)
3. Shellcodes Reference (collection + outils)
4. Exploit Education - Phoenix (pratique BOF basique)
5. HTB Challenges Pwn Easy (injection shellcode)
6. Box **October** (BOF simple sur une machine complete)
7. Box **Safe** (ROP + shellcode)
8. pwnable.kr / pwnable.tw (approfondissement)
9. Box **Ellingson** / **Rope** (exploitation avancee)

## Modules HTB Academy a faire (Binary Exploitation path)

> Path HTB Academy : **Intro to Binary Exploitation** (4 modules)
> Accessibles avec un abonnement Silver Annual (Tier II) sauf le fuzzing (Tier III / Gold).

| # | Module | Difficulte | Sections | Tier | Statut |
|---|--------|------------|----------|------|--------|
| 1 | [Intro to Assembly Language](https://academy.hackthebox.com/course/preview/intro-to-assembly-language) | Medium | 24 | II | [x] |
| 2 | [Stack-Based Buffer Overflows on Linux x86](https://academy.hackthebox.com/course/preview/stack-based-buffer-overflows-on-linux-x86) | Medium | 13 | II | [ ] |
| 3 | [Stack-Based Buffer Overflows on Windows x86](https://academy.hackthebox.com/course/preview/stack-based-buffer-overflows-on-windows-x86) | Medium | 11 | II | [ ] |
| 4 | [Introduction to Binary Fuzzing](https://academy.hackthebox.com/course/preview/introduction-to-binary-fuzzing) | Hard | 19 | III | [ ] |

### Contenu des modules

**Stack-Based Buffer Overflows on Linux x86** (13 sections) :
- Buffer Overflows Overview + CPU Architecture
- Taking Control of EIP
- Determining Shellcode Length + Bad Characters
- Generating Shellcode + Finding Return Address
- Public Exploit Modification
- Prevention Techniques (NX, ASLR, Stack Canaries)
- Skills Assessment

**Stack-Based Buffer Overflows on Windows x86** (11 sections) :
- Debugging Windows Programs (Immunity Debugger)
- Fuzzing Parameters
- Controlling EIP + Bad Characters
- Finding Return Instruction (JMP ESP)
- Jumping to Shellcode
- Remote Fuzzing + Remote Exploitation
- Skills Assessment

**Introduction to Binary Fuzzing** (19 sections) :
- Black-Box Fuzzing (Radamsa)
- White-Box Fuzzing (KLEE)
- Grey-Box Fuzzing (libFuzzer, AFL++)
- Sanitizers (ASan, MSan, UBSan)
- Crash Triaging
- Skills Assessment

> **Note** : ROP, Heap Exploitation et Format Strings n'ont pas encore de modules dedies sur HTB Academy. Pour ces sujets, utiliser Nightmare, ROP Emporium ou pwnable.kr/tw.
