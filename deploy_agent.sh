#!/bin/bash


# This deploy_agent.sh is used to deploy, run and archives logs for the attendance tracker

cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

TEMPLATES_DIR="templates"
PROJECT_DIR=""

is_number() {
    [[ "$1" =~ ^[0-9]+$ ]]
}

# This fucntion is Called when a step fails in the mid deploy and then
# prints the error and also avoids a half built project behind by removin it.
abort_deploy() {
    echo "There was this error: $1" >&2
    if [ -n "$PROJECT_DIR" ] && [ -d "$PROJECT_DIR" ]; then
        rm -rf "$PROJECT_DIR"
        echo "removed the half built directory $PROJECT_DIR." >&2
    fi
    return 1
}


# This asks for the project name and sets it's PROJECT_DIR variable.
# The name is checked because we later run rm -rf on this path.
ask_project_name() {
    local input
    read -r -p "Enter the project name, which will be used as attendance_tracker_<name>, like v1 as a name: " input
    if [ -z "$input" ]; then
        echo "an error detected: The name cannot be empty." >&2
        return 1
    fi
    if [[ ! "$input" =~ ^[A-Za-z0-9_-]+$ ]]; then
        echo "an error detected: use only letters, digits, '-' and '_'." >&2
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
        echo "There was this error: $dir does not exist. Deploy it first using option 1." >&2
        return 1
    fi
    echo "Starting the Attendance Checker in $dir ..."

    # this subshell keeps the cd from changing where this script is
    ( cd "$dir" && python3 attendance_checker.py )
}


# this whole functions is used to deploy the application
deploy_project() {
    # fail early if the tools or templates we need are missing
    if ! command -v python3 > /dev/null 2>&1; then
        echo "ERROR: python3 is not installed." >&2
        return 1
    fi
    if ! command -v zip > /dev/null 2>&1; then
        echo "ERROR: zip is not installed." >&2
        return 1
    fi
    python3 --version
    for f in attendance_checker.py assets.csv config.json; do
        if [ ! -f "$TEMPLATES_DIR/$f" ]; then
            echo "ERROR: $TEMPLATES_DIR/$f is missing." >&2
            return 1
        fi
    done

    ask_project_name || return 1

    # never overwrite silently
    if [ -d "$PROJECT_DIR" ]; then
        read -r -p "$PROJECT_DIR already exists. Overwrite? (y/n): " answer
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            rm -rf "$PROJECT_DIR"
        else
            echo "ERROR: aborted - $PROJECT_DIR was left untouched." >&2
            return 1
        fi
    fi
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
    chmod +x "$PROJECT_DIR/attendance_checker.py"
    chmod 600 "$PROJECT_DIR/Helpers/config.json"
    echo "Permissions set:"
    ls -l "$PROJECT_DIR/attendance_checker.py" "$PROJECT_DIR/Helpers/config.json"

    # optional threshold update; Enter keeps the default
    local update
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
        local cfg="$PROJECT_DIR/Helpers/config.json"
        # each pattern only matches its own line, so the file layout stays untouched
        sed -i.bak "s/\"warning\": [0-9]*/\"warning\": $warn/" "$cfg"
        sed -i.bak "s/\"failure\": [0-9]*/\"failure\": $fail/" "$cfg"
        rm -f "$cfg.bak"
        echo "Thresholds updated: warning=$warn, failure=$fail"
    fi

    echo "Deployment of $PROJECT_DIR was completed"

    # a successful start proves structure, roster and config work together
    echo "Verifying deployment by running the application..."
    run_app "$PROJECT_DIR"
}



# this is the main menu, where it stays at the bottom because bash must read the functions first.
while true; do
    echo ""
    echo "Hi user, choose one of the options below :) "
    echo ""
    echo "1 : Deploy the application"
    echo "2 : Run the application"
    echo "3 : Archive the log files"
    echo "4 : Exit"
    echo ""
    read -r -p "Choose an option 1 to 4: " option
    case "$option" in
        1) deploy_project ;;
        2) ask_project_name && run_app "$PROJECT_DIR" ;;
        3) archive_logs ;;
        4) echo "exit."; exit 0 ;;
        *) echo "you choose an invalid option, please choose 1 to 4." ;;
    esac
done
