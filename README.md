# 💙 RemLang (`.rem`)

<p align="center">
  <strong>"Starting from zero, let's build the ultimate language."</strong><br>
  <em>A modern, expressive, and high-performance programming language born out of love for Rem.</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Language-RemLang%20v0.1-38bdf8?style=for-the-badge" alt="RemLang v0.1"/>
  <img src="https://img.shields.io/badge/Extension-.rem-38bdf8?style=for-the-badge" alt=".rem extension"/>
  <img src="https://img.shields.io/badge/Paradigm-OOP%20%2B%20Procedural-9333ea?style=for-the-badge" alt="OOP + Procedural"/>
  <img src="https://img.shields.io/badge/Platform-macOS%20%7C%20Linux%20%7C%20Windows-blue?style=for-the-badge" alt="Platform"/>
  <img src="https://img.shields.io/badge/License-GPL--3.0-blue.svg?style=for-the-badge" alt="GPL 3.0 License"/>
</p>

---

## 🌟 What is RemLang?

**RemLang** is a next-generation multi-paradigm programming language utilizing the `.rem` file extension. Engineered from scratch to combine **systems-level execution speed** with an evocative, themed syntax inspired by **Rem** from *Re:Zero*, RemLang seamlessly unifies both **Procedure-Oriented Programming (POP)** and **Object-Oriented Programming (OOP)**.

Dedicated to Rem's unwavering loyalty, gentle smile, and devotion:
- **Zero Hidden Costs**: No unpredictable background pauses or hidden control flows.
- **Arena-Based Memory**: High-speed scoped arenas eliminate per-node heap fragmentation.
- **Multi-Platform**: Native compilation for macOS, Linux, and Windows with zero runtime dependencies.

---

## 💤 RemLang v0.1 Syntax Specification

### 1. Basics
| Concept | RemLang | Description |
| :--- | :--- | :--- |
| **Comments** | `zzz comment` | Single-line comment ignored until end of line |
| **Entry Point** | `rem_wakes_up { ... }` | Main program execution block |
| **End of Program** | `goodnight` | Graceful closing delimiter for programs |
| **File Extension** | `.rem` | Official source file extension |
| **Print Output** | `sleep_talk ...` | Prints expressions directly to stdout |
| **User Input** | `listen()` | Reads a line of text from stdin |

```rem
rem_wakes_up {
    sleep_talk "Good morning, Subaru-kun!"
}
goodnight
```

---

### 2. Variables & Primitive Types
| Concept | RemLang | Example |
| :--- | :--- | :--- |
| **Mutable Variable** | `remember` | `remember age = 18` |
| **Constant (Immutable)** | `promise` | `promise love = "Subaru"` |
| **Delete Variable** | `devour` | `devour age` |
| **Integer** | `whole` | `42` |
| **Float** | `drift` | `3.14` |
| **String** | `words` | `'Rem'` or `"Rem"` |
| **Boolean** | `truth` | `yes` / `no` |
| **Null** | `forgotten` | `forgotten` |
| **List** | `memories` | `[1, 2, 3]` |
| **Map (Dictionary)** | `diary` | `{ "name": "Rem", "role": "Maid" }` |

> [!NOTE]
> RemLang supports **automatic type inference**. Explicit type annotations are optional:
> ```rem
> remember whole age = 18
> remember drift pi = 3.14
> remember words hero = "Subaru"
> remember truth faithful = yes
> remember memories team = ["Rem", "Ram", "Subaru"]
> ```

---

### 3. Operators
- **Arithmetic**: `+`, `-`, `*`, `/`, `%`
- **Comparison**: `==`, `!=`, `<`, `>`, `<=`, `>=`
- **Logical**: `and`, `or`, `not`
- **Assignment**: `=`

---

### 4. Control Flow (If / Else)
| Concept | RemLang |
| :--- | :--- |
| `if` | `maybe <condition> { ... }` |
| `else if` | `or_maybe <condition> { ... }` |
| `else` | `snooze { ... }` |

```rem
maybe hope >= 5 {
    sleep_talk "Rem is waking up!"
} or_maybe hope >= 1 {
    sleep_talk "Just a little more..."
} snooze {
    sleep_talk "zzz..."
}
```

---

### 5. Loops (Iteration)
| Loop Type | RemLang | Description |
| :--- | :--- | :--- |
| **Repeat N times** | `again 3 times { ... }` | Fixed count repetition |
| **While Loop** | `again while hope < 5 { ... }` | Condition-based loop |
| **For-Each Loop** | `again each m in memories { ... }` | Iterates through each list element |
| **Break** | `wake_up` | Immediately exits loop |
| **Continue** | `turn_over` | Skips to next iteration |

```rem
remember hope = 0

again while hope < 5 {
    hope = hope + 1
    maybe hope == 2 { turn_over }
    maybe hope == 4 { wake_up }
    sleep_talk hope
}
```

---

### 6. Functions (Procedures)
| Concept | RemLang |
| :--- | :--- |
| **Function Definition** | `dream func_name(param1, param2) { ... }` |
| **Return Value** | `wake_with <value>` |
| **Function Call** | `func_name(arg1, arg2)` |

```rem
dream greet(who) {
    wake_with "Rem remembers you, " + who + "-kun~"
}
```

---

### 7. Error Handling
| Concept | RemLang | Description |
| :--- | :--- | :--- |
| `try` | `save_point { ... }` | Marks a checkpoint before risky operations |
| `catch` | `return_by_death { ... }` | Catches exceptions and unwinds safely |
| `throw` | `die "message"` | Explicitly throws a fatal error |

```rem
save_point {
    remember result = 10 / 0
} return_by_death {
    sleep_talk "Let's try again, Subaru-kun... Return by Death!"
}
```

---

### 8. Built-in Utilities
| Utility | Syntax | Description |
| :--- | :--- | :--- |
| **Import File** | `borrow "file.rem"` | Imports memory and declarations from another file |
| **List/Map Length** | `count(memories)` | Returns the number of elements |
| **Append to List** | `add(memories, item)` | Appends a new item to the list |
| **Type Reflection** | `what_is(x)` | Returns the type name string (`"whole"`, `"drift"`, `"words"`, etc.) |
| **System Clock** | `clock()` | Returns current UNIX timestamp in seconds |

---

## 🎭 Dual Programming Paradigms

RemLang gives you absolute freedom to choose your programming paradigm:

### 1. Procedure-Oriented Programming (POP)
Ideal for concise scripts, automations, and linear algorithmic pipelines:

```rem
promise beloved = "Subaru-kun"

dream calculate_score(scores) {
    remember total = 0
    again each s in scores {
        total = total + s
    }
    wake_with total
}

rem_wakes_up {
    remember memories scores = [10, 20, 30]
    add(scores, 40)
    
    sleep_talk "Total scores: " + calculate_score(scores)
    sleep_talk "Number of items: " + count(scores)
}
goodnight
```

### 2. Object-Oriented Programming (OOP)
Fully supports encapsulation, state management, `init` constructors, member methods, and `this`:

```rem
class OniMaid {
    dream init(name, role, mana) {
        this.name = name
        this.role = role
        this.mana = mana
        this.horn_active = no
    }

    dream activate_horn() {
        this.horn_active = yes
        this.mana = this.mana + 50
        sleep_talk this.name + " sprouted her glowing Oni horn! Mana: " + this.mana
    }

    dream cast_spell(spell, cost) {
        maybe this.mana < cost {
            die "Insufficient mana for " + spell + "!"
        }
        this.mana = this.mana - cost
        sleep_talk this.name + " cast [" + spell + "]! Remaining mana: " + this.mana
    }
}

rem_wakes_up {
    remember rem = new OniMaid("Rem", "Head Maid", 100)
    rem.activate_horn()
    rem.cast_spell("Al Huma", 30)
}
goodnight
```

---

## 🛠️ Installation & Build

### ⚡ Quick Install via `curl` (macOS / Linux):
```bash
curl -fsSL https://raw.githubusercontent.com/Ariefyusufwinata/RemLang/main/install.sh | bash
```

---

### 🔨 Manual Compilation from Source

#### macOS & Linux:
```bash
./build.sh
```

#### Windows:
```cmd
build.bat
```

#### Cross-Compilation for All Platforms:
```bash
./build.sh all
```

Output binaries are generated in `bin/`:
- `bin/rem` (macOS native)
- `bin/rem-linux-x86_64` (Linux static musl binary)
- `bin/rem.exe` (Windows executable)

---

## 🚀 CLI Usage

```bash
rem run examples/hello_world.rem
rem examples/procedural.rem
rem examples/oop.rem
rem rem
rem version
```

---

## 📜 License

RemLang is licensed under the **GNU General Public License v3.0 (GPL-3.0)**. See [LICENSE](LICENSE) for full details.
