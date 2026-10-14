#!/bin/bash


# This deploy_agent.sh is used to deploy, run, and archive logs for the attendance tracker

cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

TEMPLATES_DIR="templates"
PROJECT_DIR=""

is_number() {
    [[ "$1" =~ ^[0-9]+$ ]]
}

# this function responds to Ctrl+C (SIGINT) or Ctrl+Z (SIGTSTP) during deployment:
# zip whatever exists so far, then delete the half-made folder.
handle_interrupt() {
    echo ""
    echo "Attention, the deployment was interrupted by the user."
    if [ -n "$PROJECT_DIR" ] && [ -d "$PROJECT_DIR" ]; then
        local archive="${PROJECT_DIR}_archive.zip"
        echo "Archiving the incomplete project into $archive ..."
        # remove any old zip with the same name so zip creates a fresh archive instead of updating it
        rm -f "$archive"
        zip -r -q "$archive" "$PROJECT_DIR"
        echo "Removing the incomplete directory $PROJECT_DIR ..."
        rm -rf "$PROJECT_DIR"
        echo "Done. The incomplete work was saved in $archive."
       echo "This terminal session is being closed."
    else
        echo "Nothing had been created yet, so there is nothing to archive."
    fi
    exit 130
}

# This function is called when a step fails in the middle of a deployment. It
# prints the error and also avoids leaving a half-built project behind by removing it.
abort_deploy() {
    echo "There was an error: $1" >&2
    if [ -n "$PROJECT_DIR" ] && [ -d "$PROJECT_DIR" ]; then
        rm -rf "$PROJECT_DIR"
        echo "Removed the half-built directory $PROJECT_DIR." >&2
    fi
    trap - SIGINT SIGTSTP
    return 1
}


# This asks for the project name and sets its PROJECT_DIR variable.
# The name is checked because we later run rm -rf on this path.
ask_project_name() {
    local input
    read -r -p "Enter the project name, which will be used as attendance_tracker_<name> (for example, v1): " input
    if [ -z "$input" ]; then
        echo "An error was detected: the name cannot be empty." >&2
        return 1
    fi
    if [[ ! "$input" =~ ^[A-Za-z0-9_-]+$ ]]; then
        echo "An error was detected: use only letters, digits, '-' and '_'." >&2
        return 1
    fi
    PROJECT_DIR="attendance_tracker_${input}"
    return 0
}


# this runs the app from inside the project folder,
# because it reads its files using relative paths.
run_app() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        echo "There was an error: $dir does not exist. Deploy it first using option 1." >&2
        return 1
    fi
    echo "Starting the Attendance Checker in $dir ..."

    # this subshell keeps the cd from changing where this script is
    ( cd "$dir" && python3 attendance_checker.py )
}


# this whole function is used to deploy the application
deploy_project() {
    # fail early if the tools or templates we need are missing
    if ! command -v python3 > /dev/null 2>&1; then
        echo "An error was detected: python3 is not installed." >&2
        return 1
    fi
    if ! command -v zip > /dev/null 2>&1; then
        echo "An error occurred: zip is not installed." >&2
        return 1
    fi
    python3 --version
    for f in attendance_checker.py assets.csv config.json; do
        if [ ! -f "$TEMPLATES_DIR/$f" ]; then
            echo "There was an error: $TEMPLATES_DIR/$f is missing." >&2
            return 1
        fi
    done

    ask_project_name || return 1

    # never overwrite silently
    if [ -d "$PROJECT_DIR" ]; then
        read -r -p "$PROJECT_DIR already exists. Overwrite? (y/n): " answer
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            rm -rf "$PROJECT_DIR" ||
                { echo "There was an error: could not remove the old $PROJECT_DIR." >&2; return 1; }
        else
            echo "There was an error: aborted - $PROJECT_DIR was left untouched." >&2
            return 1
        fi
    fi

    trap handle_interrupt SIGINT SIGTSTP

    # structure + the two files that are always copied unchanged
    if ! mkdir -p "$PROJECT_DIR/Helpers" "$PROJECT_DIR/reports"; then
        abort_deploy "could not create directories (permission denied?)"
        return 1
    fi
    cp "$TEMPLATES_DIR/attendance_checker.py" "$PROJECT_DIR/attendance_checker.py" &&
    cp "$TEMPLATES_DIR/config.json" "$PROJECT_DIR/Helpers/config.json" ||
        { abort_deploy "could not copy template files."; return 1; }

    # roster: A = copy from the template, B = generate a fresh one
    local choice count
    while true; do
        echo "How do you want to build the roster?"
        echo "  A : Copy students from templates/assets.csv"
        echo "  B : Generate a fresh roster"
        read -r -p "Choose A or B: " choice
        [[ "$choice" =~ ^[AaBb]$ ]] && break
        echo "Please type A or B."
    done

    if [[ "$choice" =~ ^[Aa]$ ]]; then
        local available
        # minus 1 because the first line is the header
        available=$(( $(grep -c "" "$TEMPLATES_DIR/assets.csv") - 1 ))
        while true; do
            read -r -p "How many students to copy (1-$available)? " count
            is_number "$count" && [ "$count" -ge 1 ] && [ "$count" -le "$available" ] && break
            echo "Please enter a whole number between 1 and $available."
        done
        count=$((10#$count))
        # header + count rows. Template rows have 4 prior sessions,
        # so total_sessions stays 5 (the template default).
        head -n $(( count + 1 )) "$TEMPLATES_DIR/assets.csv" > "$PROJECT_DIR/Helpers/assets.csv" ||
            { abort_deploy "could not write assets.csv"; return 1; }
    else
        local names=("Alice Johnson" "Bob Smith" "Charlie Davis" "Diana Prince" "Ethan Cole" \
                     "Fatima Noor" "George Mensah" "Hannah Kim" "Ibrahim Osei" "Jasmine Lee" \
                     "Kevin Brown" "Linda Green" "Mark Evans" "Nadia Ali" "Omar Diallo")
        local emails=("alice@example.com" "bob@example.com" "charlie@example.com" "diana@example.com" "ethan@example.com" \
                      "fatima@example.com" "george@example.com" "hannah@example.com" "ibrahim@example.com" "jasmine@example.com" \
                      "kevin@example.com" "linda@example.com" "mark@example.com" "nadia@example.com" "omar@example.com")
        local max=${#names[@]}
        while true; do
            read -r -p "How many students to generate (1-$max)? " count
            is_number "$count" && [ "$count" -ge 1 ] && [ "$count" -le "$max" ] && break
            echo "Please enter a whole number between 1 and $max."
        done
        count=$((10#$count))
        # everyone starts at 0 attended / 0 absent
        {
            echo "Email,Names,Attendance Count,Absence Count"
            for (( i=0; i<count; i++ )); do
                echo "${emails[$i]},${names[$i]},0,0"
            done
        } > "$PROJECT_DIR/Helpers/assets.csv" ||
            { abort_deploy "could not write assets.csv"; return 1; }
        # no prior sessions, so today is session 1 (.bak keeps sed portable on Linux and macOS)
        sed -i.bak 's/"total_sessions": [0-9]*/"total_sessions": 1/' "$PROJECT_DIR/Helpers/config.json"
        rm -f "$PROJECT_DIR/Helpers/config.json.bak"
    fi

    # script is executable; config (grading thresholds) is owner-only
    chmod +x "$PROJECT_DIR/attendance_checker.py" &&
    chmod 600 "$PROJECT_DIR/Helpers/config.json" ||
        { abort_deploy "could not set the file permissions (chmod failed)."; return 1; }
    echo "Permissions set:"
    ls -l "$PROJECT_DIR/attendance_checker.py" "$PROJECT_DIR/Helpers/config.json"

    # optional threshold update; Enter keeps the default
    local update
    echo ""
    read -r -p "Update the attendance alert thresholds? (y/n): " update
    echo ""
    if [[ "$update" =~ ^[Yy]$ ]]; then
        local warn fail
        while true; do
            read -r -p "Warning threshold [75]: " warn
            warn=${warn:-75}
            read -r -p "Failure threshold [50]: " fail
            fail=${fail:-50}
            if ! is_number "$warn" || ! is_number "$fail"; then
                echo "Both values must be whole numbers. Try again."
            elif [ "$warn" -gt 100 ] || [ "$fail" -gt 100 ]; then
                echo "Values must be between 0 and 100. Try again."
            elif [ "$fail" -ge "$warn" ]; then
                echo "Failure must be lower than warning. Try again."
            else
                break
            fi
        done
        # strip leading zeros (075 -> 75) so the JSON stays valid
        warn=$((10#$warn)); fail=$((10#$fail))
        local cfg="$PROJECT_DIR/Helpers/config.json"
        # each pattern only matches its own line, so the file layout stays untouched
        sed -i.bak "s/\"warning\": [0-9]*/\"warning\": $warn/" "$cfg"
        sed -i.bak "s/\"failure\": [0-9]*/\"failure\": $fail/" "$cfg"
        rm -f "$cfg.bak"
        echo "Thresholds updated: warning=$warn, failure=$fail"
    fi
    trap - SIGINT SIGTSTP
    echo "Deployment of $PROJECT_DIR was completed"

    # a successful start proves structure, roster and config work together
    echo "Verifying deployment by running the application..."
    run_app "$PROJECT_DIR"
}

#  copy each existing log into its own archive folder with a timestamp
archive_logs() {
    ask_project_name || return 1
    if [ ! -d "$PROJECT_DIR" ]; then
        echo "There was an error: $PROJECT_DIR does not exist. Create it first by choosing option 1." >&2
        return 1
    fi

    local stamp
    stamp=$(date +%Y%m%d_%H%M%S)
    local archived=0

    mkdir -p "$PROJECT_DIR/archives/attendance" "$PROJECT_DIR/archives/absent" ||
        { echo "There was an error: cannot create archive directories." >&2; return 1; }

    local name src dest
    for name in attendance absent; do
        src="$PROJECT_DIR/reports/${name}.log"
        dest="$PROJECT_DIR/archives/${name}/${name}_${stamp}.log"
        if [ -f "$src" ]; then
            if cp "$src" "$dest"; then
                echo "Archived: $src -> $dest"
                archived=$(( archived + 1 ))
            else
                echo "There was an error: failed to archive $src" >&2
            fi
        else
            echo "Skipped: $src does not exist (nothing to archive)."
        fi
    done
    echo "Archive finished: $archived log(s) archived."
}



# this is the main menu. It stays at the bottom because bash must read the functions first.
while true; do
    echo ""
    echo "Hi user, choose one of the options below :) "
    echo ""
    echo "1 : Deploy the application"
    echo "2 : Run the application"
    echo "3 : Archive the log files"
    echo "4 : Exit"
    echo ""
    read -r -p "Choose an option 1 to 4: " option || { echo; echo "exit."; exit 0; }
    case "$option" in
        1) deploy_project ;;
        2) ask_project_name && run_app "$PROJECT_DIR" ;;
        3) archive_logs ;;
        4) echo "exit."; exit 0 ;;
        *) echo "You chose an invalid option. Please choose 1 to 4." ;;
    esac
done
