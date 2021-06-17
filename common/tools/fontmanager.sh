#!/bin/bash
# shellcheck shell=bash
# shellcheck disable=SC2034,SC2183,SC2154,SC1091
clear
echo "Loading..."
detect_ext_data() {
    if touch /sdcard/.rw && rm /sdcard/.rw; then
        export EXT_DATA="/sdcard/FontManager"
    elif touch /storage/emulated/0/.rw && rm /storage/emulated/0/.rw; then
        export EXT_DATA="/storage/emulated/0/FontManager"
    elif touch /data/media/0/.rw && rm /data/media/0/.rw; then
        export EXT_DATA="/data/media/0/FontManager"
    else
        EXT_DATA='/storage/emulated/0/FontManager'
        echo -e "⚠ PossiBle internal storage access issues! Please make sure data is mounted and decrypted."
        echo -e "⚠ Trying to proceed anyway "
        sleep 2
    fi
}
detect_ext_data
if test ! -d "$EXT_DATA"; then
    mkdir -p "$EXT_DATA" >/dev/null
fi
if ! touch "$EXT_DATA"/.rw && rm -fr "$EXT_DATA"/.rw; then
    if ! rm -fr "$EXT_DATA" && mkdir -p "$EXT_DATA" && touch "$EXT_DATA"/.rw && rm -fr "$EXT_DATA"/.rw; then
        echo -e "⚠ Cannot access internal storage! Falling back to module directory"
        EXT_DATA="/data/adb/modules/fontrevival"
    fi
fi
mkdir -p "$EXT_DATA"/logs >/dev/null
mkdir -p "$EXT_DATA"/lists >/dev/null
mkdir -p "$EXT_DATA"/font >/dev/null
mkdir -p "$EXT_DATA"/emoji >/dev/null
MODDIR="/data/adb/modules/fontrevival"
exec > >(tee -ia "$EXT_DATA"/logs/script.log)
exec 2> >(tee -ia "$EXT_DATA"/logs/script.log >&2)
exec 19>"$EXT_DATA"/logs/script.log
export BASH_XTRACEFD="19"
set -x
set -o functrace
shopt -s checkwinsize
shopt -s expand_aliases
. /data/adb/modules/fontrevival/tools/utils
# shellcheck disable=SC2154
if test -n "${ANDROID_SOCKET_adbd}"; then
    echo -e "ⓧ Please run this in a terminal emulator on device! ⓧ"
    exit 1
fi
if test "$(id -u)" -ne 0; then
    echo -e "${R} Please run this script as root!${N}"
    exit 1
fi
if ! $NR; then
    echo -e "${R} Do not call this script directly! Instead call just 'manage_fonts'${N}"
    it_failed
fi
TRY_COUNT=1
no_i() {
    do_banner
    echo -e "${R} No internet access!${N}"
    echo -e "${R} For now this module requires internet access${N}"
    echo -e "${R} Exiting${N}"
    sleep 3
    it_failed
}
font_select() {
    clear
    do_banner
    sleep 0.5
    echo -e "${Bl} Font changer selected. Please type the appropriate number when prompted.${N}"
    echo -e "${Bl} Proceeding to selection screen...${N}"
    echo -e "$div"
    sleep 3
    LINESTART=1
    print_list() {
        do_banner
        TOTALLINES=$(wc -l /sdcard/FontManager/lists/fonts-list.txt | awk '{ print $1 }')
        USABlELINES=$((LINES - 17))
        LINESREAD=$((LINESTART + USABlELINES))
        if test $LINESTART -ge "$TOTALLINES"; then
            LINESTART=1
            LINESREAD=$USABlELINES
        fi
        awk '{printf "\033[47;100m%d.\t%s\n", NR, $0}' <"$MODDIR"/lists/fonts-list.txt | sed -n ${LINESTART},${LINESREAD}p
        echo -e "$div"
        echo -e "${Bl} x: main menu, q: quit, enter: more, <number>: select${N}"
        echo -en "${Bl} Your choice: "
        unset a
        read -r a
        if test "$a" == ""; then
            LINESTART=$((LINESTART + USABlELINES))
            print_list
        fi
    }
    print_list
    if test "$a" == "q"; then
        do_quit
    elif test "$a" == "x"; then
        do_banner
        echo -e "${Y} Going to main menu ${N}"
        sleep 1
        menu_set
    fi
    choice=$(sed "${a}q;d" "$MODDIR"/lists/fonts-list.txt)
    if [[ -z $choice ]]; then
        do_banner
        echo -e "${R} ERROR: INVALID SELECTION${N}"
        sleep 0.5
        echo -e "${Y} Please try again${N}"
        sleep 3
        font_select
    fi
    do_banner
    dl "&s=fonts&w=&a=$choice&ft=zip" "$EXT_DATA/font/$choice.zip" "download" && sleep 1 &
    e_spinner "${Bl} Downloading $choice font "
    sleep 2
    in_f() {
        RESULTF="$EXT_DATA"/font/"$choice".zip
        if [ ! -f "$RESULTF" ]; then
            echo -e "${R} Downloaded file not found. The font was not installed.${N}"
            echo -e "${R} Returning to font selection${N}"
            sleep 2
            font_select
            return
        else
            O_S=$(md5sum "$RESULTF" | sed "s/\ \/.*//" | tr -d '[:space:]')
            T_S=$(dl "${P}&s=fonts&w=&a=$choice&ft=zip" '-' verify | tr -d '[:space:]')
            if [ "$T_S" != "$O_S" ]; then
                echo -e "${R}Downloaded file corrupt. The font was not installed.${N}"
                echo -e "${R}Returning to font selection${N}"
                sleep 2
                font_select
            fi
        fi
        unzip -o "$RESULTF" -d "$MODDIR/system/fonts" &>/dev/null
        set_perm_recursive 644 root root 0 "$MODDIR"/system/fonts/*
        if test -d /product/fonts; then
            mkdir -p "$MODDIR"/system/product/fonts
            cp "$MODDIR"/system/fonts/* "$MODDIR"/system/product/fonts/
            set_perm_recursive 644 root root 0 "$MODDIR"/system/product/fonts/*
        fi
        if test -d /system_ext/fonts; then
            mkdir -p "$MODDIR"/system/system_ext/fonts
            cp "$MODDIR"/system/fonts/* "$MODDIR"/system/system_ext/fonts/
            set_perm_recursive 644 root root 0 "$MODDIR"/system/system_ext/fonts/*
        fi
        echo "$choice" >"$MODDIR"/cfont
        sleep 1.5
    }
    in_f &
    e_spinner "${Bl} Installing $choice font "
    echo -e " "
    echo -e "${Bl} Install success!${N}"
    sleep 2
    reboot_fn
}
emoji_select() {
    clear
    do_banner
    sleep 0.5
    echo -e "${Bl} Emoji changer selected. Please type the appropriate number when prompted.${N}"
    echo -e "${Bl} Proceeding to selection screen...${N}"
    echo -e "$div"
    sleep 3
    LINESTART=1
    print_list() {
        do_banner
        TOTALLINES=$(wc -l /sdcard/FontManager/lists/emojis-list.txt | awk '{ print $1 }')
        USABlELINES=$((LINES - 17))
        LINESREAD=$((LINESTART + USABlELINES))
        if test $LINESTART -ge "$TOTALLINES"; then
            LINESTART=1
            LINESREAD=$USABlELINES
        fi
        awk '{printf "\033[47;100m%d.\t%s\n", NR, $0}' <"$MODDIR"/lists/emojis-list.txt | sed -n ${LINESTART},${LINESREAD}p
        echo -e "$div"
        echo -e "${Bl} x: main menu, q: quit, enter: more, <number>: select${N}"
        echo -en "${Bl} Your choice: "
        unset a
        read -r a
        if test "$a" == ""; then
            LINESTART=$((LINESTART + USABlELINES))
            print_list
        fi
    }
    print_list
    if test "$a" == "q"; then
        do_quit
    elif test "$a" == "x"; then
        do_banner
        echo -e "${Y} Going to main menu ${N}"
        sleep 1
        menu_set
    fi
    choice=$(sed "${a}q;d" "$MODDIR"/lists/emojis-list.txt)
    if [[ -z $choice ]]; then
        do_banner
        echo -e "${R} ERROR: INVALID SELECTION${N}"
        sleep 0.5
        echo -e "${Y} Please try again${N}"
        sleep 3
        font_select
    fi
    do_banner
    dl "&s=emojis&w=&a=$choice&ft=zip" "$EXT_DATA/emoji/$choice.zip" "download" && sleep 1 &
    e_spinner "${Bl} Downloading $choice emoji set "
    sleep 2
    in_e() {
        RESULTE="$EXT_DATA"/emoji/"$choice".zip
        if [ ! -f "$RESULTE" ]; then
            echo -e "${R} Downloaded file not found. The emoji set was not installed.${N}"
            echo -e "${R} Returning to font selection${N}"
            sleep 2
            font_select
            return
        else
            O_S=$(md5sum "$RESULTE" | sed "s/\ \/.*//" | tr -d '[:space:]')
            T_S=$(dl "${P}&s=emojis&w=&a=$choice&ft=zip" '-' verify | tr -d '[:space:]')
            if [ "$T_S" != "$O_S" ]; then
                echo -e "${R} Downloaded file corrupt. The emoji set was not installed.${N}"
                echo -e "${R} Returning to emoji selection${N}"
                sleep 2
                emoji_select
            fi
        fi
        unzip -o "$RESULTE" -d "$MODDIR/system/fonts" &>/dev/null
        set_perm_recursive 644 root root 0 "$MODDIR"/system/fonts/*
        if test -d /product/fonts; then
            mkdir -p "$MODDIR"/system/product/fonts
            cp "$MODDIR"/system/fonts/* "$MODDIR"/system/product/fonts/
            set_perm_recursive 644 root root 0 "$MODDIR"/system/product/fonts/*
        fi
        if test -d /system_ext/fonts; then
            mkdir -p "$MODDIR"/system/system_ext/fonts
            cp "$MODDIR"/system/fonts/* "$MODDIR"/system/system_ext/fonts/
            set_perm_recursive 644 root root 0 "$MODDIR"/system/system_ext/fonts/*
        fi
        if test -d /data/data/com.facebook.orca; then
            if test -d /data/data/com.facebook.orca/app_compactdisk/ras_blobs/latest/sessionless/storage; then
                cp -f "$MODDIR/system/fonts/NotoColorEmoji.ttf" "/data/data/com.facebook.orca/app_compactdisk/ras_blobs/latest/sessionless/storage/FacebookEmoji.ttf"
                FBID="$(dumpsys package com.facebook.orca | grep userId=)"
                set_perm 644 "$FBID" "$FBID" 0 "/data/data/com.facebook.orca/app_compactdisk/ras_blobs/latest/sessionless/storage/FacebookEmoji.ttf"
            fi
        fi
        echo "$choice" >"$MODDIR"/cemoji
        sleep 1.5
    }
    in_e &
    e_spinner "${Bl} Installing $choice emoji set "
    echo -e " "
    echo -e "${Bl} Install success!${N}"
    sleep 2
    reboot_fn
}
update_lists() {
    do_banner
    mkdir -p "$MODDIR"/lists
    dl_l() {
        dl "&s=lists&w=&a=fonts-list&ft=txt" "$MODDIR"/lists/fonts-list.txt "download"
        dl "&s=lists&w=&a=emojis-list&ft=txt" "$MODDIR"/lists/emojis-list.txt "download"
        sed -i s/[.]zip//gi "$MODDIR"/lists/*
        cp "$MODDIR"/lists/* "$EXT_DATA"/lists
        sleep 1.75
    }
    dl_l &
    e_spinner "${Bl} Downloading fresh lists ${N}"
    echo -e " "
    echo -e "${Y} Lists updated! Returning to menu${N}"
    sleep 2
    clear
    menu_set
}
get_id() {
    sed -n 's/^name=//p' "${1}"
}
detect_others() {
    set +x
    for i in /data/adb/modules/*/*; do
        if test "$i" != "*fontrevival" && test ! -f "$i"/disaBle && test -d "$i"/system/fonts; then
            NAME=$(get_id "$i"/module.prop)
            echo -e "${R} ⚠ ${N}"
            echo -e "${R} ⚠ Module editing font or emoji detected${N}"
            echo -e "${R} ⚠ Module - $NAME${N}"
            echo -e "${R} ⚠ Please remove said module and retry${N}"
            sleep 4
            it_failed
        fi
    done
    set -x
}
reboot_fn() {
    do_banner
    echo -e "${Bl} Do you want to reboot now?${N}"
    echo -en "${Bl} y: yes, n: return to menu: "
    read -r a
    if test "$a" == "y"; then
        /system/bin/svc power reboot || /system/bin/reboot || setprop sys.powerctl reboot
    else
        echo -e "${Y} Reboot cancelled. Returning to menu.${N}"
        sleep 2
        menu_set
    fi
}
rever_st() {
    do_banner
    r_s() {
        rm -fr "$MODDIR"/system/fonts/*
        rm -fr "$MODDIR"/system/*/fonts/*
        rm -fr "$MODDIR"/c*
        sleep 2
    }
    r_s &
    e_spinner "${Bl} Reverting to stock fonts ${N}"
    echo -e "\n${Bl} Stock fonts applied! Please reboot.${N}"
    sleep 2
    reboot_fn
}
open_link() {
    do_banner
    echo -e "${Bl} Opening https://www.androidacy.com/$1/...${N}"
    am start -a android.intent.action.VIEW -d "https://www.androidacy.com/$1/?utm_source=FontManager" &>/dev/null
    sleep 2
    echo -e "${Bl} Page should be open. Returning to menu.${N}"
    sleep 2
    menu_set
}
menu_set() {
    while :; do
        do_banner
        for i in font emoji; do
            if test ! -f $MODDIR/c$i; then
                echo "stock" >$MODDIR/c$i
            fi
        done
        echo -e "${Bl} Current font is $(cat $MODDIR/cfont)${N}"
        echo -e "${Bl} Current emoji is $(cat $MODDIR/cemoji)${N}"
        echo -e "$div"
        echo -e "${Bl} Available options:${N}"
        echo -e "${Bl}  1. Change your font${N}"
        echo -e "${Bl}  2. Change your emoji${N}"
        echo -e "${Bl}  3. Update font and emoji lists${N}"
        echo -e "${Bl}  4. Revert to stock font and emoji${N}"
        echo -e "${Bl}  5. Reboot to apply changes${N}"
        echo -e "${Bl}  6. Open font previews${N}"
        echo -e "${Bl}  7. Donate to Androidacy${N}"
        echo -e "${Bl}  8. Quit${N}"
        echo -e "$div"
        echo -en "${Bl} Your selection: "
        read -r a
        case $a in
        1*) font_select ;;
        2*) emoji_select ;;
        3*) update_lists ;;
        4*) rever_st ;;
        5*) reboot_fn ;;
        6*) open_link "font-previewer" ;;
        7*) open_link "donate" ;;
        8*) do_quit ;;
        *) echo -e "${R} Invalid option, please try again${N}" && sleep 2 && menu_set ;;
        esac
    done
}
detect_others
menu_set
