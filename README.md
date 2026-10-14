# Deploy Agent: Attendance Tracker

Deploy Agent is a single shell script, `deploy_agent.sh`, that sets up, runs, and archives the logs of a small Python attendance tracker. Instead of creating folders and copying files by hand every time, you answer a few prompts and the script builds a working project in seconds.

If you get stuck, search this page for the exact message you see; the [Troubleshooting](#6-troubleshooting-what-you-might-see-and-what-to-do) section lists every message the script can print. Not sure what a word means? See the [glossary](#11-glossary-words-youll-see) at the end.

**Video walkthrough:** https://youtu.be/JFItV70InWk
---

## Contents

1. [What is this project?](#1-what-is-this-project)
2. [Before you start: check your tools](#2-before-you-start-check-your-tools)
3. [Get the code and start the script](#3-get-the-code-and-start-the-script)
4. [The files this project uses](#4-the-files-this-project-uses)
5. [The three features, step by step](#5-the-three-features-step-by-step)
6. [Troubleshooting: what you might see and what to do](#6-troubleshooting-what-you-might-see-and-what-to-do)
7. [Pressing Ctrl+C or Ctrl+Z during deployment](#7-pressing-ctrlc-or-ctrlz-during-deployment)
8. [A 5-minute guided walkthrough](#8-a-5-minute-guided-walkthrough)
9. [How I tested the deployed structure](#9-how-i-tested-the-deployed-structure)
10. [Quick reference](#10-quick-reference)
11. [Glossary: words you'll see](#11-glossary-words-youll-see)

---

## 1. What is this project?

Picture a teacher taking attendance. For every student, the question is simply "were you here today, yes or no?". A **Python program** (`attendance_checker.py`) already handles that: it asks those questions, keeps count, and warns about students who miss too many classes.

That program is picky, though. It only works when its files sit in exactly the right folders, and setting that up by hand every time is slow. One typo in a folder name is enough to break it.

**This project is a script that does that setup for you.** It's called `deploy_agent.sh`, and it can do three things:

1. **Deploy:** build a ready-to-use project folder with everything in the right place.
2. **Run:** start the attendance program inside that folder.
3. **Archive:** save timestamped copies of the log files the program produces.

It also cleans up after itself. If you cancel in the middle of a deployment, it won't leave a half-built mess behind (see [section 7](#7-pressing-ctrlc-or-ctrlz-during-deployment)).

### What's in this repo

```
deploy_agent_hwa-pyong-maniragaba-edouard/
├── deploy_agent.sh          # the script you run
├── README.md                # you are here
├── .gitignore               # keeps test projects and zips out of Git
└── templates/               # the three original, untouched source files
    ├── attendance_checker.py
    ├── assets.csv           # sample roster: 10 students, 4 earlier sessions each
    └── config.json          # thresholds 75 / 50, total_sessions = 5
```

### Which files are mine, and which are not?

| File                              | Who wrote it          | Changed by this project?                             |
| --------------------------------- | --------------------- | ---------------------------------------------------- |
| `templates/attendance_checker.py` | Provided starter file | **No, never**                                        |
| `templates/assets.csv`            | Provided starter file | **No, never**                                        |
| `templates/config.json`           | Provided starter file | **No, never**                                        |
| `deploy_agent.sh`                 | Written by me         | This is the script                                   |
| `README.md`                       | Written by me         | Documentation                                        |
| `.gitignore`                      | Written by me         | Git settings: it hides generated test files from Git |

The three files in `templates/` are **originals that stay untouched**. When you deploy, the script makes _copies_ of them inside a new project folder, and only the copies get edited (for example, when you change the alert thresholds). Deploy as many times as you like: the originals are always safe.

### Why there's a `.gitignore`

Every time you test the script, it creates things that aren't part of the source code: test projects (`attendance_tracker_<name>/`) and interrupt archives (`attendance_tracker_<name>_archive.zip`). The `.gitignore` file tells Git to skip them, along with the `*.bak` files that `sed` can leave behind and the `*.swp` files that vim creates while you edit.

Without it, `git status` would fill up with test output after every run, and it would be easy to commit that clutter by accident. With it, the repository only contains the files that matter: the script, the templates, and the documentation.

---

## 2. Before you start: check your tools

The script needs three tools. Let's check whether you already have them.

| Tool         | Why it's needed                                                                                                |
| ------------ | -------------------------------------------------------------------------------------------------------------- |
| **Git**      | To download (clone) this project. _Optional:_ you can skip it by using GitHub's "Download ZIP" button instead. |
| **Python 3** | To run the attendance program. (Python 3.6 or newer; any modern install is fine.)                              |
| **zip**      | So the script can save an interrupted deployment as a `.zip`.                                                  |

### Step 1: open a terminal

- **Linux:** press `Ctrl+Alt+T`, or search for "Terminal".
- **macOS:** press `Cmd+Space`, type "Terminal", and press Enter.
- **Windows:** this script can't run in plain PowerShell or Command Prompt. See [Windows users](#windows-users-read-this) below first.

### Step 2: run these three commands, one at a time

```bash
git --version
python3 --version
zip -v | head -2
```

Each command should print a version. Your numbers will probably differ, and that's fine:

```
git version 2.43.0
Python 3.12.3
Copyright (c) 1990-2008 Info-ZIP - Type 'zip "-L"' for software license.
This is Zip 3.0 (July 5th 2008), by Info-ZIP.
```

If a command prints `command not found` (or something similar), that tool is missing. Install it using the instructions for your system below, then run the check again.

### Installing what's missing

**Ubuntu, Debian, Linux Mint, Pop!\_OS:**

```bash
sudo apt update
sudo apt install git python3 zip
```

**Fedora, RHEL, CentOS:**

```bash
sudo dnf install git python3 zip
```

**Arch, Manjaro:**

```bash
sudo pacman -S git python zip
```

**macOS:**

- Python and Git: the first time you run `git --version` or `python3 --version`, macOS may pop up a window asking you to install the "command line developer tools". Click **Install** and wait for it to finish. (If you use [Homebrew](https://brew.sh), `brew install git python` also works.)
- `zip` comes pre-installed on macOS, so there's nothing to do.

### Windows users: read this

The script is written for **Bash**, which Windows doesn't have built in. The easiest fix is **WSL** (Windows Subsystem for Linux), which gives you a real Linux terminal inside Windows:

1. Open **PowerShell as Administrator** (right-click the Start menu).
2. Run `wsl --install` and restart the computer when asked.
3. Open **Ubuntu** from the Start menu and create a username and password when asked.
4. Inside the Ubuntu window, follow the **Ubuntu/Debian** commands above, then continue with this README from there.

Git Bash can also run the script, but it usually **doesn't include `zip`**, so the script's pre-flight check would stop you. WSL is the smoother path.

---

## 3. Get the code and start the script

### Option 1: with Git (recommended)

```bash
git clone https://github.com/hwa-pyong-maniragaba-edouard/deploy_agent_hwa-pyong-maniragaba-edouard.git
cd deploy_agent_hwa-pyong-maniragaba-edouard
```

`git clone` downloads the project into a new folder, and `cd` ("change directory") moves your terminal _into_ that folder.

### Option 2: without Git

On the GitHub page, click the green **Code** button, then **Download ZIP**. Unzip it, then `cd` into the unzipped folder in your terminal.

### Start the script

```bash
chmod +x deploy_agent.sh
./deploy_agent.sh
```

What these do:

- `chmod +x` gives the file permission to run as a program. You only need to do this once. (Git remembers the permission if you cloned, but a downloaded ZIP forgets it.)
- `./deploy_agent.sh` runs it. The `./` means "the file in the current folder".

> **"Permission denied"?** Your files may be on a USB drive or a Windows-formatted disk, where Linux isn't allowed to run files directly. Use this instead, which always works: `bash deploy_agent.sh`

You should now see the main menu:

```
Hi user, choose one of the options below :)

1 : Deploy the application
2 : Run the application
3 : Archive the log files
4 : Exit

Choose an option 1 to 4:
```

Type a number and press **Enter**. After each action, the menu comes back until you choose `4`.

**How features are selected:** I chose an **interactive menu** rather than command-line flags, so there's nothing to memorise. All three features (and Exit) are one number away.

---

## 4. The files this project uses

Before using the features, it helps to know what the attendance program reads and writes. These are all plain text, so you can open them in any text editor (or print one in the terminal with `cat filename`).

### `assets.csv`: the class roster

A table of students. The first line names the columns, and each following line is one student:

```
Email,Names,Attendance Count,Absence Count
alice@example.com,Alice Johnson,4,0
bob@example.com,Bob Smith,1,3
```

Read the second line as: _Alice Johnson, email alice@example.com, has attended 4 sessions and missed 0_. Bob has attended 1 and missed 3. The provided sample has **10 students**, each with **4 earlier sessions** recorded (attended + missed = 4).

Every time you mark attendance, the program updates these two counts.

### `config.json`: the settings

```json
{
  "thresholds": {
    "warning": 75,
    "failure": 50
  },
  "run_mode": "live",
  "total_sessions": 5
}
```

- **`warning: 75`**: a student whose attendance is _below 75%_ gets a **WARNING**.
- **`failure: 50`**: a student _below 50%_ gets an **URGENT** alert ("will fail this class").
- **`total_sessions: 5`**: the total number of sessions _including today's_.
- **`run_mode`**: leave this as `live`; it lets the program print an alert line for absent students.

**How the percentage is worked out:** `sessions attended ÷ total_sessions × 100`. Bob attended 1 of 5 sessions, which is 20%. That's under 50, so he's URGENT.

**Why `total_sessions` is 5, not 4:** it counts today as well. The sample students each had 4 earlier sessions, and today's makes 5. The rule is always: `total_sessions` = earlier sessions + 1. The script keeps these consistent for you, so you never have to calculate it.

### `attendance_checker.py`: the attendance program

The Python program itself. You never need to read or edit it. When you run it, it:

1. Reads the roster and the settings.
2. Asks you about each student: `[P]resent or [A]bsent?`
3. Prints their new attendance percentage and any warning.
4. Saves the updated counts back into `assets.csv`.
5. Writes the two log files described below.

It only works if its files are in this exact layout, which is what the script builds for you:

```
attendance_tracker_v1/
├── attendance_checker.py
├── Helpers/
│   ├── assets.csv
│   └── config.json
└── reports/                 (starts empty; the program fills it)
```

### The log files (in `reports/`)

The program creates these the first time you run it, and each session adds new lines at the end.

- **`attendance.log`**: one line for every student marked, whether present or absent.
- **`absent.log`**: one line only for students marked _absent_. If nobody was absent, this file is never created. That's normal, not a bug.

Here's roughly what the lines look like (your dates, names, and numbers will differ, and the program adds fractions of a second to the time):

`attendance.log`:

```
=== Session recorded 2026-10-13 16:13:02.654321 | total_sessions=5 | mode=live ===
[2026-10-13 16:13:05.123456] Alice Johnson <alice@example.com>: PRESENT - attended 5/5 = 100.0%
[2026-10-13 16:13:09.234567] Bob Smith <bob@example.com>: ABSENT - attended 1/5 = 20.0% | URGENT: below the failure threshold - will fail this class
```

`absent.log`:

```
=== Session recorded 2026-10-13 16:13:02.654321 | total_sessions=5 | mode=live ===
[2026-10-13] Bob Smith <bob@example.com> - absent (now 20.0% attendance) | URGENT: below the failure threshold - will fail this class
```

---

## 5. The three features, step by step

### Feature 1: Deploy the application (menu option `1`)

This builds a complete, working project. The script goes through these steps in order.

**Step 1: safety checks.** Before creating anything, the script checks that `python3` and `zip` are installed, shows your Python version, and confirms the three template files exist. If anything is missing, it stops at once with a message, so nothing half-built is left behind.

**Step 2: name your project.**

```
Enter the project name, which will be used as attendance_tracker_<name> (for example, v1):
```

Type something like `v1`, and the folder will be called `attendance_tracker_v1`. The rules for the name:

- It can't be empty.
- Only letters, digits, `-`, and `_` are allowed (no spaces, no `/`, no dots).

The restriction is there for safety. The script may later delete this folder, so the name must never be able to point somewhere else on your computer.

**What if that project already exists?** The script never overwrites silently. It asks:

```
attendance_tracker_v1 already exists. Overwrite? (y/n):
```

- `y` deletes the old folder and builds a fresh one. Anything you recorded in it is lost.
- Anything else (like `n`) cancels. The old folder stays exactly as it was, and you return to the menu.

**Step 3: create the folders and copy the files.** The script builds the layout shown in [section 4](#4-the-files-this-project-uses) and copies `attendance_checker.py` and `config.json` from `templates/`, unchanged. If any step fails (for example, you don't have permission to write in that location), it prints the error and **removes the half-built folder**, so you're never left with a broken project.

**Step 4: choose how to build the roster.**

```
How do you want to build the roster?
  A : Copy students from templates/assets.csv
  B : Generate a fresh roster
Choose A or B:
```

|                              | Option A: Copy                                         | Option B: Generate                                    |
| ---------------------------- | ------------------------------------------------------ | ----------------------------------------------------- |
| **What it does**             | Copies students from the sample `templates/assets.csv` | Builds new students from name lists inside the script |
| **How many?**                | You choose 1 to 10 (the sample has 10)                 | You choose 1 to 15                                    |
| **Starting counts**          | The sample's existing counts (4 earlier sessions each) | Everyone at 0 attended / 0 absent                     |
| **`total_sessions` becomes** | Stays **5**                                            | Set to **1**                                          |
| **Use it when**              | You want a roster that already has some history        | You want a brand-new class with no history            |

_Why different values?_ Remember the rule: `total_sessions` = earlier sessions + 1. Option A's students have 4 earlier sessions, so the total is 5. Option B's students have none, so today is the first session, and the total is 1. For Option B, the script uses `sed` (a find-and-replace tool) to change that number in the copy of `config.json`.

If you type something that isn't a valid choice or number, the script simply asks again.

**Leading zeros are fine.** If you type the student count as `08` or `010`, the script reads it as the plain decimal numbers 8 and 10. (Bash normally treats a number that starts with `0` as _octal_, which would make `08` an error and `010` silently mean 8. After the count is validated, the script converts it with `count=$((10#$count))` so this can't happen.)

**Step 5: set permissions.** Two permission rules are applied, and the result is printed so you can see it:

| File                    | Permission  | Meaning                                                                                                   |
| ----------------------- | ----------- | --------------------------------------------------------------------------------------------------------- |
| `attendance_checker.py` | `chmod +x`  | It is allowed to run as a program.                                                                        |
| `Helpers/config.json`   | `chmod 600` | Only you (the owner) can read or change it. The thresholds decide who gets flagged, so they're protected. |

In the printed list, `-rwx...` means executable, and `-rw-------` means owner-only read and write.

**Step 6: optionally change the alert thresholds.**

```
Update the attendance alert thresholds? (y/n):
```

- **`n`**: keep the defaults (warning 75, failure 50).
- **`y`**: you're asked for two numbers. Press **Enter** on either one to keep its default (shown in `[brackets]`).

```
Warning threshold [75]:
Failure threshold [50]:
```

Your numbers are checked _before_ the script edits anything. It asks again if:

| What you typed                                 | What the script says                             |
| ---------------------------------------------- | ------------------------------------------------ |
| Letters, or anything that isn't a whole number | `Both values must be whole numbers. Try again.`  |
| A number over 100                              | `Values must be between 0 and 100. Try again.`   |
| A failure value that isn't lower than warning  | `Failure must be lower than warning. Try again.` |

Once the values pass, `sed` rewrites **only** the `"warning"` and `"failure"` lines in the project's `config.json`. The rest of the file is not reformatted or reordered, and the original in `templates/` isn't touched.

**Step 7: verify by running the app.** The script finishes by launching the attendance program. If the program starts, that proves the folders, the roster, and the settings all fit together.

> **Important:** this verification run is a _real_ marking session. The students you mark are saved into the roster and the logs, so by the time deployment finishes, session one is already recorded. If you just want a quick look, type `P` for everyone.

### Feature 2: Run the application (menu option `2`)

Use this on a project you've already deployed. Enter the project name, and the script runs:

```bash
cd attendance_tracker_v1
python3 attendance_checker.py
```

(The `cd` happens in a temporary subshell, so the script itself stays where it was.)

The program asks about each student:

```
Mark Alice Johnson <alice@example.com> - [P]resent or [A]bsent?
```

- Type `P` for present or `A` for absent (capital or small letter both work), then press Enter.
- Anything else, and it politely asks again.
- After each answer you see their percentage, plus a **WARNING** or **URGENT** note if they're under a threshold. For an absent student with an alert, it also prints `Logged alert for <name>`.
- At the end you'll see something like: `Done. Marked 3 students, 1 absent. Logs: reports/attendance.log, reports/absent.log`.

**If the project doesn't exist:** you'll see `There was an error: ... does not exist. Deploy it first using option 1.` and you return to the menu.

**A quirk you'll notice if you run the same project twice.** Every run adds _one more_ session to each student's counts, but `total_sessions` in the config stays the same. So on the second run you'll see notes like:

```
(note: Alice Johnson has 5 prior sessions on record, expected 4 - proceeding anyway)
```

and percentages over 100% (for example, 120%). That is the Python program's own behaviour. The Python program has to stay unmodified in this project, so the script doesn't hide it. Nothing is broken, and the program keeps going ("proceeding anyway"). For a clean demo, deploy a fresh project.

### Feature 3: Archive the log files (menu option `3`)

After a marking session, this saves a dated copy of your logs. **The trigger is manual:** nothing is archived on its own, only when you choose option `3`.

Enter the project name, and the script checks for `reports/attendance.log` and `reports/absent.log`. Each log that exists is copied into its own archive folder, with the date and time added to the filename:

```
attendance_tracker_v1/
└── archives/
    ├── attendance/
    │   └── attendance_20261013_161519.log
    └── absent/
        └── absent_20261013_161519.log
```

The timestamp reads `YYYYMMDD_HHMMSS`, so `20261013_161519` means 13 October 2026 at 16:15:19. Because the time is in the name, every copy is unique and you can tell when it was made. Both logs from one archive run share the same timestamp, so you can see they belong together.

You get one line per file and a summary:

```
Archived: attendance_tracker_v1/reports/attendance.log -> attendance_tracker_v1/archives/attendance/attendance_20261013_161519.log
Skipped: attendance_tracker_v1/reports/absent.log does not exist (nothing to archive).
Archive finished: 1 log(s) archived.
```

**Different situations:**

| Situation                                         | What happens                                                                                        |
| ------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| Both logs exist                                   | Both are copied, and the summary says 2 archived.                                                   |
| Only `attendance.log` exists (nobody was absent)  | That one is archived. The other is reported as skipped, and the script carries on without crashing. |
| You haven't run the app yet, so there are no logs | Both are reported as skipped, and the summary says `0 log(s) archived`.                             |
| The project doesn't exist                         | An error tells you to create it first by choosing option 1.                                         |

The logs are **copied, not moved**, so the originals stay in `reports/`. If you archive again later, the new copy will include the older sessions too. That's harmless, but good to know.

### Exiting (menu option `4`)

Prints `exit.` and closes the script.

---

## 6. Troubleshooting: what you might see and what to do

| What you see                                                                                  | What it means                                                          | What to do                                                                                      |
| --------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| `bash: ./deploy_agent.sh: Permission denied`                                                  | The file isn't marked as runnable, or your drive blocks running files. | `chmod +x deploy_agent.sh`, or use `bash deploy_agent.sh`.                                      |
| `bash: ./deploy_agent.sh: No such file or directory`                                          | You're in the wrong folder, or the name is misspelled.                 | Run `ls` to see the files, and `cd` into the project folder.                                    |
| `command not found` for `git`, `python3`, or `zip`                                            | That tool isn't installed.                                             | See [section 2](#2-before-you-start-check-your-tools).                                          |
| `python3 is not installed`                                                                    | The script's safety check couldn't find Python.                        | Install Python 3, then start again.                                                             |
| `zip is not installed`                                                                        | Same, but for `zip`.                                                   | Install `zip`, then start again.                                                                |
| `templates/<file> is missing`                                                                 | One of the three template files isn't where the script expects it.     | Make sure the `templates/` folder sits next to `deploy_agent.sh`. Re-clone if needed.           |
| `the name cannot be empty`                                                                    | You pressed Enter without typing a name.                               | Choose the option again and type a name.                                                        |
| `use only letters, digits, '-' and '_'`                                                       | Your name had a space, slash, dot, or another special character.       | Use something like `v1` or `class_2026`.                                                        |
| `... already exists. Overwrite? (y/n)`                                                        | A project with that name is already there.                             | `y` replaces it (old data is lost). `n` keeps it.                                               |
| `aborted - ... was left untouched`                                                            | You said no to overwriting.                                            | Nothing was changed. Pick a different name, or answer `y` next time.                            |
| `Please type A or B.`                                                                         | Invalid roster choice.                                                 | Type `A` or `B`.                                                                                |
| `Please enter a whole number between 1 and N.`                                                | The student count was text, zero, or too big.                          | Type a whole number in the range shown. A leading zero is fine (`08` counts as 8).              |
| Threshold messages (`must be whole numbers`, `between 0 and 100`, `lower than warning`)       | Invalid threshold values.                                              | Re-enter them. Press Enter to keep the defaults.                                                |
| `could not create directories`, `could not copy template files`, `could not write assets.csv` | The script couldn't write files (often permissions or a full disk).    | Check that you can write in this folder. The script has already removed the half-built project. |
| `... does not exist. Deploy it first using option 1.`                                         | You chose Run for a project that was never created.                    | Use option `1` first, or check the spelling of the name (`v1` and `V1` are different).          |
| `... does not exist. Create it first by choosing option 1.`                                   | You chose Archive for a project that was never created.                | Same as above.                                                                                  |
| `You chose an invalid option. Please choose 1 to 4.`                                          | The menu input wasn't 1, 2, 3, or 4.                                   | Type a number from 1 to 4.                                                                      |
| `... has 5 prior sessions on record, expected 4`                                              | You ran the same project again; see the quirk in Feature 2.            | Expected behaviour. Carry on, or deploy a fresh project.                                        |
| Percentages above 100%                                                                        | Same cause as above.                                                   | Same as above.                                                                                  |
| I pressed Ctrl+C at the menu and the script just quit                                         | Normal. Nothing was being built, so there's nothing to clean up.       | Start again with `./deploy_agent.sh`.                                                           |
| I pressed Ctrl+Z at the menu and the terminal says `Stopped`                                  | Ctrl+Z _pauses_ a program.                                             | Type `fg` and press Enter to bring it back.                                                     |
| `git status` shows lots of `attendance_tracker_*` files                                       | The `.gitignore` is missing or was edited.                             | Make sure `.gitignore` is in the repo root (see [section 10](#10-quick-reference)).             |

---

## 7. Pressing Ctrl+C or Ctrl+Z during deployment

Deployment is the one moment where cancelling could leave a half-built folder lying around, so the script guards it.

**The archive trigger:** the interrupt itself. The moment the script receives Ctrl+C (SIGINT) or Ctrl+Z (SIGTSTP) while the guard is on, it saves what exists into a `.zip` and then cleans up. It never does this at any other time.

**When the guard is on:** from just before the project folder is created until the thresholds step is finished. It is switched off before the verification run, so Ctrl+C during a _marking session_ behaves normally (the Python program handles it).

**Why it starts only after the overwrite question:** the cleanup deletes the project folder. If the guard were already on while you were being asked about overwriting an _existing_ project, pressing Ctrl+C could delete work that this run never created. By starting after the folder is ours, the cleanup only ever deletes what this run built.

**What happens when you interrupt (while the guard is on):**

1. The script prints that the deployment was interrupted.
2. Whatever exists of `attendance_tracker_<name>/` is saved into `attendance_tracker_<name>_archive.zip` in the main project folder (next to `deploy_agent.sh`). It's made with the `zip` command, so it has a real `.zip` extension.
3. The incomplete folder is deleted, so there is no clutter.
4. The script exits cleanly instead of crashing.

What you see on screen looks like this:

```
Attention, the deployment was interrupted by the user.
Archiving the incomplete project into attendance_tracker_v1_archive.zip ...
Removing the incomplete directory attendance_tracker_v1 ...
Done. The incomplete work was saved in attendance_tracker_v1_archive.zip.
This terminal session is being closed.
```

**If you interrupt at other moments:**

| When you press Ctrl+C / Ctrl+Z                       | What happens                                                                                                                                                                                                                                                              |
| ---------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| At the main menu                                     | Ctrl+C quits quietly. Ctrl+Z pauses the script (type `fg` to resume).                                                                                                                                                                                                     |
| At the project-name or overwrite question            | The guard isn't on yet, so Ctrl+C just ends the script and Ctrl+Z pauses it (`fg` resumes). Nothing has been created by this run, so there's nothing to clean up. (If you had already answered `y` to the overwrite question, the old project was deleted at that point.) |
| Anywhere from folder creation to the thresholds step | The save-and-clean-up described above.                                                                                                                                                                                                                                    |
| While marking students in the Python program         | Handled by the Python program, not the script. It saves the students already marked.                                                                                                                                                                                      |

### How to test it yourself

1. Run `./deploy_agent.sh` and choose `1`.
2. Enter a name such as `v1` (and answer the overwrite question if you're asked).
3. At `Choose A or B:` (or at the student-count prompt after it), press **Ctrl+C**.
4. Look at the result:

```bash
ls
unzip -l attendance_tracker_v1_archive.zip
```

- `ls` should show `attendance_tracker_v1_archive.zip` and **no** `attendance_tracker_v1` folder.
- `unzip -l` lists what's inside the zip. If you interrupt at `Choose A or B:` or at the student-count prompt, it contains `attendance_checker.py`, `Helpers/config.json`, and an empty `reports/` folder, because the roster hadn't been built yet. (If you interrupt later, for example at the thresholds prompt, the zip also contains `Helpers/assets.csv`.)

Repeat with **Ctrl+Z** and compare: you should get the same result. Clean up the test zip afterwards with `rm attendance_tracker_v1_archive.zip`.

---

## 8. A 5-minute guided walkthrough

Follow this once and you'll have seen every feature in action. Lines starting with `>` are what you type.

1. Start the script and choose Deploy:

```
> ./deploy_agent.sh
> 1
```

2. Name the project and build the roster:

```
Enter the project name ... : > v1
Choose A or B: > A
How many students to copy (1-10)? > 3
```

3. Skip changing the thresholds:

```
Update the attendance alert thresholds? (y/n): > n
```

4. The verification run starts. Mark the three students (with the default thresholds of 75 and 50):

```
Mark Alice Johnson <alice@example.com> - [P]resent or [A]bsent? > P
  -> 100.0% attendance | on track
Mark Bob Smith <bob@example.com> - [P]resent or [A]bsent? > A
  -> 20.0% attendance | URGENT: below the failure threshold - will fail this class
  Logged alert for Bob Smith
Mark Charlie Davis <charlie@example.com> - [P]resent or [A]bsent? > P
  -> 60.0% attendance | WARNING: below the warning threshold - please be careful
```

5. Back at the menu, archive the logs:

```
> 3
Enter the project name ... : > v1
Archived: attendance_tracker_v1/reports/attendance.log -> attendance_tracker_v1/archives/attendance/attendance_<timestamp>.log
Archived: attendance_tracker_v1/reports/absent.log -> attendance_tracker_v1/archives/absent/absent_<timestamp>.log
Archive finished: 2 log(s) archived.
```

6. Exit, then look at what was built:

```
> 4
> find attendance_tracker_v1 | sort
```

---

## 9. How I tested the deployed structure

After a deployment, I check the result with:

```bash
find attendance_tracker_v1 | sort
ls -l attendance_tracker_v1/attendance_checker.py attendance_tracker_v1/Helpers/config.json
cat attendance_tracker_v1/Helpers/config.json
head attendance_tracker_v1/Helpers/assets.csv
```

What I look for:

- The layout matches the required structure exactly (`Helpers/`, `reports/`, the script), with the capital `H` in `Helpers`.
- `attendance_checker.py` shows `-rwx...` (runnable) and `config.json` shows `-rw-------` (owner only).
- `config.json` has the thresholds I chose, and a `total_sessions` of 5 (Option A) or 1 (Option B).
- `assets.csv` has a header plus exactly the number of students I asked for.
- The app starts and runs a marking session, which is the script's own verification step.

I also tried the awkward cases on purpose, to make sure they fail politely:

| I tried                                                           | Expected result                                                                                |
| ----------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| An empty project name, or a name like `a/b`                       | An error, then the menu                                                                        |
| Deploying over an existing project and answering `n`              | "aborted ... left untouched"                                                                   |
| Deploying over an existing project and answering `y`              | The old folder is replaced by a fresh one                                                      |
| A student count of `abc`, `0`, or one that is too large           | A message and a re-prompt                                                                      |
| A student count with a leading zero, such as `08`, `09`, or `010` | Accepted and read as 8, 9, and 10 (not as octal), so the roster has exactly that many students |
| Threshold `abc`, `150`, or failure not below warning              | A message and a re-prompt                                                                      |
| Pressing Enter at both threshold prompts                          | Defaults 75 and 50 are used                                                                    |
| Option B, then checking `config.json`                             | `total_sessions` is 1                                                                          |
| Running a project that doesn't exist                              | A clear error, no crash                                                                        |
| Archiving a project that doesn't exist                            | A clear error, no crash                                                                        |
| Archiving when there is no `absent.log`                           | One log archived, one skipped                                                                  |
| Archiving when someone was absent                                 | Both logs archived, one file in each archive folder                                            |
| An invalid menu option                                            | A message, then the menu                                                                       |
| Ctrl+C and Ctrl+Z mid-deployment                                  | A zip is created and the half-built folder is gone                                             |

---

## 10. Quick reference

| I want to...                       | Do this                                                                                |
| ---------------------------------- | -------------------------------------------------------------------------------------- |
| Check my tools                     | `git --version`, `python3 --version`, `zip -v \| head -2`                              |
| Start the script                   | `./deploy_agent.sh` (or `bash deploy_agent.sh`)                                        |
| Set up a new project               | Menu `1`                                                                               |
| Take attendance                    | Menu `2`                                                                               |
| Save the logs                      | Menu `3`                                                                               |
| Leave                              | Menu `4`                                                                               |
| Start a project over               | Deploy it again and answer `y` to overwrite, or run `rm -rf attendance_tracker_<name>` |
| See what's inside an interrupt zip | `unzip -l attendance_tracker_<name>_archive.zip`                                       |
| See why Git is ignoring a file     | `git check-ignore -v <name>`                                                           |

### Notes

- Test projects (`attendance_tracker_*/`) and interrupt zips (`attendance_tracker_*_archive.zip`) are generated output, not source code. The included `.gitignore` keeps them out of Git, along with the `*.bak` files left by `sed` and the `*.swp` files left by vim, so `git status` stays clean after you test. If you want to see which rule is hiding a file, run `git check-ignore -v <name>`.
- Ignored doesn't mean deleted: test projects stay on your disk until you remove them with `rm -rf attendance_tracker_*`.
- The script always changes into its own folder first, so you can start it from anywhere.

---

## 11. Glossary: words you'll see

Not sure what a word means? Here is what each one means in this project.

| Word                        | What it means here                                                                                                                                                            |
| --------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Terminal**                | A window where you type commands instead of clicking. You'll type everything for this project there.                                                                          |
| **Shell / Bash**            | The program inside the terminal that understands your commands. Bash is the most common one.                                                                                  |
| **Shell script**            | A text file full of terminal commands that run one after another. `deploy_agent.sh` is one (`.sh` = shell).                                                                   |
| **Directory**               | Another word for _folder_.                                                                                                                                                    |
| **Repository (repo)**       | A project folder tracked by Git, usually stored on GitHub.                                                                                                                    |
| **Clone**                   | Download a repo from GitHub to your computer.                                                                                                                                 |
| **`.gitignore`**            | A file that tells Git which files to skip, such as test output you don't want to commit.                                                                                      |
| **Python**                  | A programming language. `attendance_checker.py` is written in it (`.py` = Python).                                                                                            |
| **CSV**                     | "Comma-separated values": a spreadsheet saved as plain text, one row per line, with values split by commas. `assets.csv` is one.                                              |
| **JSON**                    | A plain-text way of storing settings as `"name": value` pairs. `config.json` is one.                                                                                          |
| **Log file**                | A plain-text diary a program writes as it works, one line per event.                                                                                                          |
| **Roster**                  | The list of students in the class.                                                                                                                                            |
| **Session**                 | One class meeting where attendance is taken.                                                                                                                                  |
| **Threshold**               | A cut-off percentage. Below it, a student is warned.                                                                                                                          |
| **Octal**                   | A number system that uses only the digits 0 to 7. Bash reads a number starting with `0` (like `010`) as octal, which is why the script converts the student count with `10#`. |
| **Permissions**             | Rules about who may read, change, or run a file.                                                                                                                              |
| **ZIP**                     | One compressed file that holds a whole folder inside it.                                                                                                                      |
| **Signal (Ctrl+C, Ctrl+Z)** | A message you send to a running program from the keyboard. Ctrl+C means "stop", Ctrl+Z means "pause".                                                                         |
| **Timestamp**               | The date and time written into something, such as a filename.                                                                                                                 |
