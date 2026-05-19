#!/usr/bin/env bash

# Declares variables from a directory. .txt extension for simple variables, .array for arrays.
restsh.util.setvars() {
    local OPTION OPTIND
    local FIND_OPTS=("-maxdepth" "1")
    while getopts ':r' OPTION
    do
        case "$OPTION" in
            r) FIND_OPTS=() ;;
            *) OPTION="invalid"; break ;;
        esac
    done
    shift "$((OPTIND -1))"
    if [ -z "${1+x}" ] || [ "$OPTION" = "invalid" ]
    then
        {
            echo "Declares variables from a directory. .txt extension for simple variables, .array for arrays."
            echo "See restsh.util.setvar -h for further details"
            echo ""
            echo "Usage: restsh.util.setvars [options...] <directory>"
            echo "Options:"
            echo "    -r Recurse into directories"
        } 1>&2
        return 2
    fi
    local DIR=$1
    echo "Reading configuration from \"$DIR\""
    local DEF
    while read -r DEF
    do
        restsh.util.setvar "$DEF"
    done < <(find "$DIR" "${FIND_OPTS[@]}" -type f -name \*.txt -or -name \*.array)
    # Warn for skipped files
    local INVALID
    INVALID=$(find "$DIR" -type f -printf "%f\n" | grep -Pv '^((\w+)\.(array|txt|inc)|\.gitkeep)$' || true)
    if [ -n "$INVALID" ]
    then
        echo_warn "Skipped files in folder \"$DIR\":"
        local FILE
        for FILE in "${INVALID[@]}"
        do
            echo_warn "- \"$FILE\""
        done
    fi
}

# Declares a variable from a file. .txt extension for simple variable, .array for array.
restsh.util.setvar() {
    if [ -z "${1+x}" ] || [ "${1}" = "-h" ]
    then
        {
            echo "Declares a variable from a file. .txt extension for simple variable, .array for array."
            echo "  .txt files are treated as variable and declared as VAR_<file basename>"
            echo "  .array files are treated as array and declared as ARRAY_<file basename>"
            echo "Blank lines and lines starting with # are ignored."
            echo ""
            echo "Usage: restsh.util.setvar <file>"
        } 1>&2
        return 2
    fi
    local FILE=$1
    # Check if file exists
    if [ ! -f "$FILE" ]
    then
        echo_err "File does not exist: \"$FILE\""
        return 1
    fi
    # Extract filename and extension
    local FILENAME="${FILE##*/}"
    local BASENAME="${FILENAME%.*}"
    local EXT="${FILENAME##*.}"
    local REGEX='^[a-zA-Z][0-9a-zA-Z_]+$'
    if ! [[ "$BASENAME" =~ $REGEX ]]
    then
        echo_err "Invalid characters in filename."
        echo_err "Must contain only alphanumeric characters and underscores."
        return 1
    fi
    # strings, concatenates multiple lines
    if [ "$EXT" == "txt" ]
    then
        # construct variable name
        local VAR="VAR_${BASENAME}"
        # set variable from config file
        local VALUE
        VALUE="$(grep -v -P '^(#|\s*$)' "$FILE" | tr -d '\r\n' || true)"
        declare -g -x "$VAR"="$VALUE"
        echo "Declaring variable: \"$VAR\""
    elif [ "$EXT" == "array" ]
    then
        # construct array name
        local VAR="ARRAY_${BASENAME}"
        # set array from config file
        local LINES
        LINES=$(grep -v -P '^(#|\s*$)' "$FILE" | tr -d '\r' || true)
        if [ -n "$LINES" ]
        then
            mapfile -t "$VAR" <<< "$LINES"
            echo "Declaring array: \"$VAR\""
        else
            declare -g -a "$VAR=()"
            echo "Declaring empty array: \"$VAR\""
        fi
    else
        echo_err "Invalid file type: \"$EXT\""
        return 1
    fi
}

# Returns a comma if it is not the first item in a loop.
# Usage: {{MO_COMMA_IF_NOT_FIRST}}
MO_COMMA_IF_NOT_FIRST() {
    [[ "${MO_CURRENT#*.}" != "0" ]] && printf ","
    return 0
}

# Returns a comma if arguments are not empty.
# Usage: {{MO_COMMA_IF_NOT_EMPTY 'VAR_NAME_1' 'VAR_NAME_2' 'VAR_NAME_3'}}
MO_COMMA_IF_NOT_EMPTY() {
    local ARG_COUNT=${#MO_FUNCTION_ARGS[@]}
    local MAX_ARG_INDEX=$((ARG_COUNT-1))
    local BEFORE_VALUES=""
    # Join arguments but last
    local COUNT=0
    local ARG
    set +u # Do not fail if not defined
    for ARG in "${MO_FUNCTION_ARGS[@]}"
    do
        BEFORE_VALUES="${BEFORE_VALUES}${!ARG}"
        COUNT=$((COUNT+1))
        # Exit loop before last
        [ $COUNT -eq $MAX_ARG_INDEX ] && break
    done
    # Get last argument
    ARG=${MO_FUNCTION_ARGS[$MAX_ARG_INDEX]}
    local LAST_VALUE
    LAST_VALUE=${!ARG}
    set -u
    if [ -n "$BEFORE_VALUES" ] && [ -n "$LAST_VALUE" ]
    then
        printf ","
    fi
}

# Prints variable value or provided default if the variable is empty.
# Usage: {{MO_VALUE_OR_DEFAULT 'VAR_BAD_UNESCAPE' 'true'}}
MO_VALUE_OR_DEFAULT() {
    local ARG=${MO_FUNCTION_ARGS[0]}
    local DEFAULT=${MO_FUNCTION_ARGS[1]}
    set +u # Do not fail if not defined
    local VALUE="${!ARG}"
    set -u
    if [ -n "$VALUE" ]
    then 
        printf "%s" "$VALUE"
    else
        printf "%s" "$DEFAULT"
    fi
}

# Prints the expanded variable value of first two arguments or provided default (last value) if the variable is empty.
# Usage: {{MO_VALUE_EXPAND_OR_DEFAULT 'VAR_JSON_MAX_ARRAY_LENGTH_' {{JCP_FRIENDLY_VAR}} {{VAR_JSON_MAX_ARRAY_LENGTH}}}}
MO_VALUE_EXPAND_OR_DEFAULT() {
    local ARG=${MO_FUNCTION_ARGS[0]}${MO_FUNCTION_ARGS[1]}
    local DEFAULT=${MO_FUNCTION_ARGS[2]}
    set +u # Do not fail if not defined
    local VALUE="${!ARG}"
    set -u
    if [ -n "$VALUE" ]
    then
        printf "%s" "$VALUE"
    else
        printf "%s" "$DEFAULT"
    fi
}

# Prints true if variable is not empty, else false.
# Usage: {{MO_TRUE_IF_NOT_EMPTY 'VAR_HOSTNAMES'}}
MO_TRUE_IF_NOT_EMPTY() {
    local ARG=${MO_FUNCTION_ARGS[0]}
    set +u
    local VALUE="${!ARG}"
    set -u
    if [ -n "${VALUE}" ]
    then
        printf "true"
    else
        printf "false"
    fi
}

# Returns the first entry from a comma separated list.
# Usage: {{MO_CSV_GET_FIRST {{.}}}}
MO_CSV_GET_FIRST() {
    local VALUE=${MO_FUNCTION_ARGS[0]}
    printf "%s" "${VALUE%%,*}"
}

# Returns the last entry from a comma separated list.
# Usage: {{MO_CSV_GET_LAST {{.}}}}
MO_CSV_GET_LAST() {
    local VALUE=${MO_FUNCTION_ARGS[0]}
    printf "%s" "${VALUE##*,}"
}

# Returns an entry from a comma separated list.
# Usage: {{MO_CSV_GET_ENTRY {{.}} '1'}}
MO_CSV_GET_ENTRY() {
    local VALUE=${MO_FUNCTION_ARGS[0]}
    local NR=${MO_FUNCTION_ARGS[1]}
    local CSV
    mapfile -t -d, CSV <<< "$VALUE"
    printf "%s" "${CSV[$NR]}" | tr -d '\n'
}

# Returns an entry from a comma separated list or default value if not found.
# Usage: {{MO_CSV_GET_ENTRY {{.}} '1' 'default'}}
MO_CSV_GET_ENTRY_OR_DEFAULT() {
    local VALUE=${MO_FUNCTION_ARGS[0]}
    local NR=${MO_FUNCTION_ARGS[1]}
    local DEFAULT=${MO_FUNCTION_ARGS[2]}
    local CSV
    mapfile -t -d, CSV <<< "$VALUE"
    if [ "${#CSV[@]}" -le "$NR" ]
    then
        printf "%s" "$DEFAULT"
    else
        printf "%s" "${CSV[$NR]}" | tr -d '\n'
    fi
}

# Prints the override signature declaration for parameters.
# Usage: {{MO_PARAMETERS_GET_DISABLE_SIGNATURES {{.}}}}
MO_PARAMETERS_GET_DISABLE_SIGNATURES() {
    local LINE="${MO_FUNCTION_ARGS[0]}"
    local SIGNATURES="${LINE##*,}"
    MO_PRINT_SIGNATURE_OVERRIDES "$SIGNATURES"
}

# Prints value length declaration for parameters.
# Usage: {{MO_PARAMETERS_GET_VALUE_LENGTH {{.}}}}
MO_PARAMETERS_GET_VALUE_LENGTH() {
    local LINE="${MO_FUNCTION_ARGS[0]}"
    local CSV
    mapfile -t -d, CSV <<< "$LINE"
    local LENGTH=${CSV[2]}
    if [ "$LENGTH" -ne 0 ]
    then
        printf '"checkMaxValueLength":true,"maximumLength":%s,' "$LENGTH"
    else
        printf '"checkMaxValueLength":false,'
    fi
}

# Prints the wildcard declaration for an url.
# Usage: {{MO_URLS_GET_TYPE {{.}}}}
MO_URLS_GET_TYPE() {
    local LINE="${MO_FUNCTION_ARGS[0]}"
    local CSV
    mapfile -t -d, CSV <<< "$LINE"
    local WILDCARD=${CSV[2]}
    if [ "$WILDCARD" = "true" ]
    then
        printf ',"type":"wildcard","wildcardIncludesSlash":true'
    fi
}

# Prints the content profile declaration for an url.
# Usage: {{MO_URLS_GET_CONTENT_PROFILE {{.}}}}
MO_URLS_GET_CONTENT_PROFILE() {
    local LINE="${MO_FUNCTION_ARGS[0]}"
    local CSV
    mapfile -t -d, CSV <<< "$LINE"
    local CONTENT_TYPE=${CSV[4]}
    local CONTENT_PROFILE=${CSV[5]}
    if [ -n "$CONTENT_PROFILE" ]
    then
        CONTENT_PROFILE="\"contentProfile\" : { \"name\" : \"$CONTENT_PROFILE\" },"
    fi
    if [ -n "$CONTENT_TYPE" ]
    then
        printf ',"urlContentProfiles":[{%s"headerName":"*","headerOrder":"default","headerValue":"*","type":"%s"}]' "$CONTENT_PROFILE" "$CONTENT_TYPE"
    fi
}

# Prints the override signature declaration for an url.
# Usage: {{MO_URLS_GET_DISABLED_SIGNATURES {{.}}}}
MO_URLS_GET_DISABLED_SIGNATURES() {
    local LINE="${MO_FUNCTION_ARGS[0]}"
    local CSV
    mapfile -t -d, CSV <<< "$LINE"
    local SIGNATURES=${CSV[7]}
    MO_PRINT_SIGNATURE_OVERRIDES "$SIGNATURES"
}

# General function to print the override signature declaration.
# Usage: {{MO_PRINT_SIGNATURE_OVERRIDES 'space separated signature ids'}}
MO_PRINT_SIGNATURE_OVERRIDES() {
    local SIGNATURES=$1
    # Iterate through space separated signature ids
    local COUNT=0
    local V
    local COMMA=""
    for V in $SIGNATURES
    do
        [ $COUNT -gt 0 ] && printf ","
        printf '%s\n{"enabled":false,"signatureId":%s}' "$COMMA" "$V"
        COMMA=","
    done
}

# Function to print the rather big charset array
# Usage: {{MO_PRINT_CHARSET 'ARRAY_REF'}}
MO_PRINT_CHARSET() {
    local ARRAY_REF="${MO_FUNCTION_ARGS[0]}"
    local ARRAY="${ARRAY_REF}[@]"
    local LINE
    local COMMA=""
    for LINE in "${!ARRAY}"
    do
        mapfile -t -d, CSV <<< "$LINE"
        printf '%s\n{"isAllowed":%s,"metachar":"%s"}' "$COMMA" "${CSV[1]}" "${CSV[0]}"
        COMMA=","
    done
}

# Parses the file with mustache before including it
# Usage: {{MO_INCLUDE_PARSE '<filename>'}}
# Usage: {{MO_INCLUDE_PARSE '<filename>' '<basedir>'}}
MO_INCLUDE_PARSE() {
    local FILENAME
    if [ -n "${MO_FUNCTION_ARGS[1]+x}" ] && [ -n "${MO_FUNCTION_ARGS[1]}" ]
    then
        FILENAME="${MO_FUNCTION_ARGS[1]}/${MO_FUNCTION_ARGS[0]}"
    else
        FILENAME="${MO_FUNCTION_ARGS[0]}"
    fi
    mo -- "$FILENAME"
}

# Parses the variable with mustache before including it.
# Usage: {{MO_VAR_PARSE '<text>'}}
MO_VAR_PARSE() {
    local ARG="${MO_FUNCTION_ARGS[0]}"
    local VALUE="${!ARG}"
    mo -- <<< "$VALUE"
}

# Includes the variable if condition is true.
# Usage: {{MO_VAR_PARSE_IF 'F5_VERSION' '17' 'VARIABLE'}}
MO_VAR_PARSE_IF() {
    local ARG="${MO_FUNCTION_ARGS[0]}"
    local VALUE="${!ARG}"
    if [ "$VALUE" = "${MO_FUNCTION_ARGS[1]}" ]
    then
        ARG="${MO_FUNCTION_ARGS[2]}"
        VALUE="${!ARG}"
        mo -- <<< "$VALUE"
    fi
}
