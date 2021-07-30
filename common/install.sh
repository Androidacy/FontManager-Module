# shellcheck shell=ash
# shellcheck disable=SC2169,SC2121,SC2154
ui_print "ⓘ Welcome to Font Manager!"
xml_s() {
	ui_print "ⓘ Registering our fonts"
	SXML="$MODPATH"/system/etc/fonts.xml
	if test -z "$MAGISKTMP"; then
		MAGISKTMP=$(magisk --path)/.magisk
	fi
	if test -d "$MAGISKTMP"; then
		OD=$MAGISKTMP/mirror
	fi
	mkdir -p "$MODPATH"/system/etc
	cp -rf "$OD"/system/etc/fonts.xml "$MODPATH"/system/etc
	DF=$(sed -n '/"sans-serif">/,/family>/p' "$SXML" | grep '\-Regular.' | sed 's/.*">//;s/-.*//' | tail -1)
	if ! grep -q 'family >' "$SXML"; then
		sed -i '/"sans-serif">/,/family>/H;1,/family>/{/family>/G}' "$SXML"
		sed -i ':a;N;$!ba;s/name="sans-serif"//2' "$SXML"
	fi
	set BlackItalic Black BoldItalic Bold MediumItalic Medium Italic Regular LightItalic Light ThinItalic Thin
	for i; do
		sed -i "/\"sans-serif\">/,/family>/s/$DF-$i/Roboto-$i/" "$SXML"
	done
	set BlackItalic Black BoldItalic Bold MediumItalic Medium Italic Regular LightItalic Light ThinItalic Thin
	for i; do
		sed -i "s/NotoSerif-$i/Roboto-$i/" "$SXML"
	done
	if grep -q OnePlus "$SXML"; then
		if test -f "$OD"/system/etc/fonts_base.xml; then
			local OXML=$SYSETC/fonts_base.xml
			cp "$SXML" "$OXML"
			sed -i "/\"sans-serif\">/,/family>/s/$DF/Roboto/" "$OXML"
		fi
	fi
	if grep -q miui "$SXML"; then
		set Black Bold Medium Regular Light Thin
		if test "$i" = "Black"; then
			sed -i '/"mipro-bold"/,/family>/{/700/s/MiLanProVF/Black/;/stylevalue="700"/d}' "$SXML"
			sed -i '/"mipro-heavy"/,/family>/{/400/s/MiLanProVF/Black/;/stylevalue="700"/d}' "$SXML"
		elif test "$i" = "Bold"; then
			sed -i '/"mipro"/,/family>/{/700/s/MiLanProVF/Bold/;/stylevalue="400"/d}' "$SXML"
			sed -i '/"mipro-medium"/,/family>/{/700/s/MiLanProVF/Bold/;/stylevalue="480"/d}' "$SXML"
			sed -i '/"mipro-demibold"/,/family>/{/700/s/MiLanProVF/Bold/;/stylevalue="540"/d}' "$SXML"
			sed -i '/"mipro-semibold"/,/family>/{/700/s/MiLanProVF/Bold/;/stylevalue="630"/d}' "$SXML"
			sed -i '/"mipro-bold"/,/family>/{/400/s/MiLanProVF/Bold/;/stylevalue="630"/d}' "$SXML"
		elif test "$i" = "Medium"; then
			sed -i '/"mipro-regular"/,/family>/{/700/s/MiLanProVF/Medium/;/stylevalue="400"/d}' "$SXML"
			sed -i '/"mipro-medium"/,/family>/{/400/s/MiLanProVF/Medium/;/stylevalue="400"/d}' "$SXML"
			sed -i '/"mipro-demibold"/,/family>/{/400/s/MiLanProVF/Medium/;/stylevalue="480"/d}' "$SXML"
			sed -i '/"mipro-semibold"/,/family>/{/400/s/MiLanProVF/Medium/;/stylevalue="540"/d}' "$SXML"
		elif test "$i" = "Regular"; then
			sed -i '/"mipro"/,/family>/{/400/s/MiLanProVF/Regular/;/stylevalue="340"/d}' "$SXML"
			sed -i '/"mipro-light"/,/family>/{/700/s/MiLanProVF/Regular/;/stylevalue="305"/d}' "$SXML"
			sed -i '/"mipro-normal"/,/family>/{/700/s/MiLanProVF/Regular/;/stylevalue="340"/d}' "$SXML"
			sed -i '/"mipro-regular"/,/family>/{/400/s/MiLanProVF/Regular/;/stylevalue="340"/d}' "$SXML"
		elif test "$i" = "Light"; then
			sed -i '/"mipro-thin"/,/family>/{/700/s/MiLanProVF/Light/;/stylevalue="200"/d}' "$SXML"
			sed -i '/"mipro-extralight"/,/family>/{/700/s/MiLanProVF/Light/;/stylevalue="250"/d}' "$SXML"
			sed -i '/"mipro-light"/,/family>/{/400/s/MiLanProVF/Light/;/stylevalue="250"/d}' "$SXML"
			sed -i '/"mipro-normal"/,/family>/{/400/s/MiLanProVF/Light/;/stylevalue="305"/d}' "$SXML"
		elif test "$i" = "Thin"; then
			sed -i '/"mipro-thin"/,/family>/{/400/s/MiLanProVF/Thin/;/stylevalue="150"/d}' "$SXML"
			sed -i '/"mipro-extralight"/,/family>/{/400/s/MiLanProVF/Thin/;/stylevalue="200"/d}' "$SXML"
		fi
	fi
	if grep -q lg-sans-serif "$SXML"; then
		sed -i '/"lg-sans-serif">/,/family>/{/"lg-sans-serif">/!d};/"sans-serif">/,/family>/{/"sans-serif">/!H};/"lg-sans-serif">/G' "$SXML"
	fi
	if [ -f "$OD"/system/etc/fonts_lge.xml ]; then
		cp -rf "$OD"/system/etc/fonts_lge.xml "$MODPATH"/system/etc
		local LXML=$SYSETC/fonts_lge.xml
		set BlackItalic Black BoldItalic Bold MediumItalic Medium Italic Regular LightItalic Light ThinItalic Thin
		for i; do
			sed -i "/\"default_roboto\">/,/family>/s/Roboto-$i/$i/" "$LXML"
		done
	fi
	if grep -q Samsung "$SXML"; then
		sed -i 's/SECRobotoLight-/Roboto-/' "$SXML"
		sed -i 's/SECCondensed-/RobotoCondensed-/' "$SXML"
	fi
	if grep -q COLOROS "$SXML"; then
		if [ -f "$OD"/system/etc/fonts_base.xml ]; then
			local RXML=$SYSETC/fonts_base.xml
			cp "$SXML" "$RXML"
			sed -i "/\"sans-serif\">/,/family>/s/$DF/Roboto/" "$RXML"
		fi
	fi
}
get_lists() {
	ui_print "ⓘ Excellent, you have internet."
	ui_print "ⓘ Downloading extra files..."
	mkdir -p "$MODPATH"/lists
	mkdir -p "$EXT_DATA"/lists
	mkdir -p "$EXT_DATA"/font
	mkdir -p "$EXT_DATA"/emoji
	downloadFile 'lists' 'fonts-list' 'txt' "$MODPATH/lists/fonts.list"
	downloadFile 'lists' 'emojis-list' 'txt' "$MODPATH/lists/emojis.list"
	sed -i 's/[.]zip$//g' "$MODPATH"/lists/*
	updateChecker 'lists'
	echo "$response" >"$MODPATH"/lists/lists.version
	mkdir -p "$MODPATH"/system/etc
	mkdir -p "$MODPATH"/system/fonts
	cp -f "$MODPATH"/lists/* "$EXT_DATA"/lists
	xml_s
}
setup_script() {
	chmod 755 -R "$MODPATH"/system/bin/
	mkdir "$MODPATH"/system/fonts
}
extra_cleanup() {
	mkdir "$MODPATH"/tools/
	mv "$MODPATH"/common/tools/fontmanager.sh "$MODPATH"/tools/fontmanager
	mv "$MODPATH"/common/apiClient.sh "$MODPATH"/tools/apiClient
	mv "$MODPATH"/common/tools/utils.sh "$MODPATH"/tools/utils
	mv "$MODPATH/common/tools/bash-$ARCH" "$MODPATH/tools/bash"
	mv "$MODPATH/common/tools/curl-$ARCH" "$MODPATH/tools/curl"
	rm -fr "$MODPATH"/common/
	rm -rf "$MODPATH"/*.md
	rm -rf "$MODPATH"/LICENSE
}
get_lists
setup_script
extra_cleanup
{
	echo "Here's some useful links:"
	echo " "
	echo "Website: https://www.androidacy.com"
	echo "Donate: https://www.androidacy.com/donate/"
	echo "Support and contact: https://www.anroidacy.com/contact/"
} >"$EXT_DATA"/README.txt
ui_print "⚠ Please make sure not to have any other font changing modules installed ⚠"
ui_print "⚠ Please remove any such module, as it conflicts with this one ⚠"
ui_print "ⓘ Once you reboot, run 'su -c manage_fonts' in TermUX (recommended) or similiar"
sleep 1
am start -a android.intent.action.VIEW -d "https://www.androidacy.com/install-done/?r=fmi&v=5.0.1_beta4" >/dev/null