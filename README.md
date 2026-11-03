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

**RemLang** is a next-generation multi-paradigm programming language utilizing the `.rem` file extension. Engineered from scratch to combine **systems-level execution speed** with an evocative, themed syntax inspired by **Rem** from *Re:Zero*, RemLang unifies both **Procedure-Oriented Programming (POP)** and **Object-Oriented Programming (OOP)**.

Dedicated to Rem's unwavering loyalty, gentle smile, and devotion:
- **Zero Hidden Costs**: No unpredictable background pauses or hidden control flows.
- **Arena-Based Memory**: High-speed scoped arenas eliminate per-node heap fragmentation.
- **Multi-Platform**: Native compilation for macOS, Linux, and Windows with zero runtime dependencies.

---

## 💤 RemLang v0.1 Syntax Specification

### 1. Dasar (Basics)
| Konsep | RemLang | Catatan |
| :--- | :--- | :--- |
| **Komentar** | `zzz komentar` | Mengabaikan teks hingga akhir baris |
| **Entry Point** | `rem_wakes_up { ... }` | Blok utama eksekusi program |
| **Akhir Program** | `goodnight` | Penutup program yang manis |
| **Ekstensi File** | `.rem` | Ekstensi resmi RemLang |
| **Print Output** | `sleep_talk ...` | Mencetak ke stdout |
| **Input Pengguna** | `listen()` | Membaca satu baris string dari stdin |

```rem
zzz Hello World in RemLang 💤
rem_wakes_up {
    sleep_talk "Good morning, Subaru-kun!"
}
goodnight
```

---

### 2. Variabel & Tipe Primitif
| Konsep | RemLang | Contoh |
| :--- | :--- | :--- |
| **Variabel (Mutable)** | `remember` | `remember age = 18` |
| **Konstanta (Immutable)**| `promise` | `promise love = "Subaru"` |
| **Hapus Variabel** | `devour` | `devour age` |
| **Integer** | `whole` | `42` |
| **Float** | `drift` | `3.14` |
| **String** | `words` | `'Rem'` atau `"Rem"` |
| **Boolean** | `truth` | `yes` / `no` |
| **Null** | `forgotten` | `forgotten` |
| **List** | `memories` | `[1, 2, 3]` |
| **Map (Dictionary)** | `diary` | `{ "name": "Rem", "role": "Maid" }` |

> [!NOTE]
> RemLang mendukung **type inference otomatis**. Tipe eksplisit bersifat opsional:
> ```rem
> remember whole age = 18
> remember drift pi = 3.14
> remember words hero = "Subaru"
> remember truth faithful = yes
> remember memories team = ["Rem", "Ram", "Subaru"]
> ```

---

### 3. Operator
- **Aritmetika**: `+`, `-`, `*`, `/`, `%`
- **Perbandingan**: `==`, `!=`, `<`, `>`, `<=`, `>=`
- **Logika**: `and`, `or`, `not`
- **Assignment**: `=`

---

### 4. Percabangan (If / Else)
| Konsep | RemLang |
| :--- | :--- |
| `if` | `maybe <kondisi> { ... }` |
| `else if` | `or_maybe <kondisi> { ... }` |
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

### 5. Perulangan (Iteration)
| Jenis Perulangan | RemLang | Penjelasan |
| :--- | :--- | :--- |
| **Repeat N kali** | `again 3 times { ... }` | Loop hitungan pasti |
| **While Loop** | `again while hope < 5 { ... }` | Loop berbasis kondisi |
| **For-Each Loop** | `again each m in memories { ... }`| Iterasi setiap elemen list |
| **Break** | `wake_up` | Keluar dari perulangan |
| **Continue** | `turn_over` | Lanjut ke iterasi berikutnya |

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

### 6. Fungsi (Prosedur)
| Konsep | RemLang |
| :--- | :--- |
| **Definisi Fungsi** | `dream nama_fungsi(param1, param2) { ... }` |
| **Return Value** | `wake_with <nilai>` |
| **Pemanggilan** | `nama_fungsi(arg1, arg2)` |

```rem
dream greet(who) {
    wake_with "Rem remembers you, " + who + "-kun~"
}
```

---

### 7. Penanganan Kesalahan (Error Handling)
| Konsep | RemLang | Deskripsi |
| :--- | :--- | :--- |
| `try` | `save_point { ... }` | Menandai save point sebelum kode berbahaya |
| `catch` | `return_by_death { ... }` | Menangkap kesalahan dan mengembalikan timeline |
| `throw` | `die "pesan"` | Melempar kesalahan fatal secara eksplisit |

```rem
save_point {
    remember result = 10 / 0
} return_by_death {
    sleep_talk "Let's try again, Subaru-kun... Return by Death!"
}
```

---

### 8. Built-in Utilities
| Fungsi | Sintaks | Keterangan |
| :--- | :--- | :--- |
| **Import File** | `borrow "file.rem"` | Meminjam modul/ingatan dari file lain |
| **Panjang List/Map** | `count(memories)` | Menghitung jumlah elemen |
| **Tambah ke List** | `add(memories, item)` | Menambahkan elemen baru ke list |
| **Cek Tipe** | `what_is(x)` | Mengembalikan string tipe (`"whole"`, `"drift"`, `"words"`, dll.) |
| **Waktu Sistem** | `clock()` | Mengambil timestamp detik saat ini |

---

## 🎭 Dual Programming Paradigms

RemLang memberikan kebebasan mutlak dalam memilih paradigma pemrograman:

### 1. Procedure-Oriented Programming (POP)
Cocok untuk script cepat, otomasi, dan algoritma pipeline:

```rem
zzz POP Example (examples/procedural.rem) 💤

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
Mendukung enkapsulasi, state internal, konstruktor `init`, member methods, dan `this`:

```rem
zzz OOP Example (examples/oop.rem) 💤

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
# Build for all targets (macOS + Linux + Windows)
./build.sh all
```

Output binaries are generated in `bin/`:
- `bin/rem` (macOS native)
- `bin/rem-linux-x86_64` (Linux static musl binary)
- `bin/rem.exe` (Windows executable)

---

## 🚀 CLI Usage

```bash
# Run a RemLang program
rem run examples/hello_world.rem

# Direct execution shortcut
rem examples/procedural.rem
rem examples/oop.rem

# Display Rem ASCII art
rem rem

# Check RemLang version
rem version
```

### Rem ASCII Art Banner 💙
```text
                      .-===+%+*%=--.
                  :=*%%*++*+*==*+****++*==:
               .+%#%*=:-==-+-  :..+*+%## %+%*..
             .+%#*=.   :=+*##%%%%#*+=:   %@=@###@@@+
            ++##-   :*%@@@@@@@@@@@@%*: =  ::=#@@=%##@#@@=
           %-@#   +%@@@@@@@@@@@@@@@@# :*  .- :#@*#+*#@@+=
          %.%@  *@@@@@@@@@@@@@@@@@@.   @+:.=#@%@#@+*@@#**
         *- @  %@@@@@@@@@@@@@@@@@#    .=*#%@##=*@@+@@@@@@
        :* .: =@@@@@@@@@@@@@@@@@=     := -@+ :: *@@-@*@*@
        %- :  #@@@@@@@@@@@@@@@@+      -=*..-@# * %*#@@@@@%
        @= =: @@@@@@@@@@@@@@@@*       -=*=::  *#@   @##@=@@
       .@=::= *@@@@@@@@@@@*-::        %***===.  %.  %@@@@@:
       :@+- %= =@@@@@@@#=:            @@*@@@@@@@+--=@*=@@@
       .@%::@@==%@@@@@-               #@%  @@#@-@#=:@+%=@@@
        @#= %*@#*@:+#= :+%=..*+        --. -@=@%=+-@@#
        =@*-:=#@@@-                   .@@@##*:+@@@.
         =@@# -=%@-         .         . #=.*:#@#=@.
          .%@@%+.++       \___/        += -@@@@-.@
             .=@@#@*=.               +%+@%@*:=@.
                 =@*@@%+:        :+#@@+@*.   :.
                    .#@@.:--::--:.@@@:
    ::.  :.         .%=-=:.    .:=-=*          .:  .::
   :* .:=**%=..    :-%=  + +..+ +  =%-:    ..=%**=:. *:
   -=      .*@.-*+:.   = :: %% :: =   .:+*-.@*.      =-
    #        +-:@@      .=#*%%*#=.      @@:-+        #
    :%@+:--- == .#@   =%*==@@@@==*%=   @#. == ---:+@%:
     -@. .-+=.#++ *@+ =@=*@@..@@*=@= +@* ++#.=+-. .@-
     #%      =+*+*. %@***=**  **=***@% .*+*==      %#
    -= %. .-:%*: +=.+= *=#=#**#=#=* =+.=+ :*%:-. .% =-
```

---

## 📜 License

RemLang is licensed under the **GNU General Public License v3.0 (GPL-3.0)**. See [LICENSE](LICENSE) for full details.
