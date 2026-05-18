#!/usr/bin/env bash

MO_COMMA_IF_NOT_FIRST() {
    [[ "${MO_CURRENT#*.}" != "0" ]] && printf ","
    return 0
}
