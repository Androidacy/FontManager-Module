# shellcheck shell=ash
# Don't modify anything after this
if [ -f "$INFO" ]; then
  while read -r LINE; do
    if [ "$(echo -n "$LINE" | tail -c 1)" = "~" ]; then
      continue
    elif [ -f "$LINE~" ]; then
      mv -f "$LINE~" "$LINE"
    else
      rm -f "$LINE"
      while true; do
        LINE=$(dirname "$LINE")
        # shellcheck disable=SC2015
        [ "$(ls -A "$LINE" 2>/dev/null)" ] && break 1 || rm -rf "$LINE"
      done
    fi
  done <"$INFO"
  rm -f "$INFO"
fi
echo "# FontManager Cleanup Script
while test \"$(getprop sys.boot_completed)\" != \"1\"  && test ! -d /storage/emulated/0/Android ;
do sleep 2;
done
rm -rf /storage/emulated/0/FontManager
rm -rf /data/adb/service.d/fm-cleanup.sh
exit 0" >/data/adb/service.d/fm-cleanup.sh
chmod 755 /data/adb/service.d/fm-cleanup.sh
sync && sleep 1
reboot
