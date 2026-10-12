#!/usr/bin/env bash
# Runs the behavior suite and reports failures as behaviors.
#
#   tools/behavior-report.sh                 L1 and L2, on Mac and iPad
#   tools/behavior-report.sh --mac           Mac only
#   tools/behavior-report.sh --ipad          iPad only
#   tools/behavior-report.sh --with-l3       also the L3 smoke flows (Mac only, ~4 min)
#
# L3 is optional: it types real keys, so nobody may use the Mac while it runs
# (decided 2026-10-10; revisit once tests can run on a second Mac).
#
# Output: "all green", or one line per broken behavior:
#   ED-010 · Tab indents a row under its previous sibling… · Mac
# Failing tests without a behavior ID (e.g. upstream tests) are listed separately.
#
# Exit status: 0 all green, 1 failures, 2 a build or run error.

set -uo pipefail
source "$(dirname "$0")/behavior-common.sh"

usage() { echo "usage: tools/behavior-report.sh [--mac|--ipad] [--with-l3]" >&2; exit 2; }

LAYERS="L1 L2"
destinations=("Mac" "iPad")
for arg in "$@"; do
	case "$arg" in
		--mac)     destinations=("Mac") ;;
		--ipad)    destinations=("iPad") ;;
		--with-l3) LAYERS="L1 L2 L3" ;;
		*) usage ;;
	esac
done

broken=""
unmapped=""
errors=""

for platform in "${destinations[@]}"; do
	if [ "$platform" = "Mac" ]; then destination="$MAC_DESTINATION"; else destination="$IPAD_DESTINATION"; fi
	for layer in $LAYERS; do
		# L3 smoke flows are Mac-only.
		[ "$layer" = "L3" ] && [ "$platform" != "Mac" ] && continue
		scheme="$(scheme_for_layer "$layer")"
		echo "… $layer on $platform" >&2

		log="$DERIVED_DATA/report-$layer-$platform.log"
		mkdir -p "$DERIVED_DATA"
		run_tests "$scheme" "$destination" > "$log"

		if ! grep -qE "Test run with [0-9]+ tests?" "$log"; then
			errors+="$layer on $platform: build failed or tests didn't run (log: ${log#$REPO_ROOT/})"$'\n'
			continue
		fi

		# Swift Testing prints: ✘ Test "Display name" failed after …   or   ✘ Test name() failed after …
		# Lines may start with zero-width spaces; the run summary ("✘ Test run with …") isn't a test.
		parsed=0
		while IFS= read -r name; do
			[ -z "$name" ] && continue
			parsed=$((parsed + 1))
			# L3 flows confirm several behaviors and start with all their IDs ("ED-054 ED-057 Delete at …").
			ids="$(echo "$name" | grep -oE '^([A-Z]{2,3}-[0-9]{3} )+' | grep -oE '[A-Z]{2,3}-[0-9]{3}')"
			where="$platform"
			[ "$layer" = "L3" ] && where="$platform (L3 smoke flow)"
			if [ -n "$ids" ]; then
				for id in $ids; do
					sentence="$(inventory_field "$(inventory_row "$id")" 2)"
					broken+="$id · ${sentence:-<not in BEHAVIORS.md>} · $where"$'\n'
				done
			else
				unmapped+="$name · $layer · $platform"$'\n'
			fi
		done < <(perl -CSD -Mutf8 -ne '
				s/\x{200B}//g;
				next if /^✘ Test run with /;
				print(($1 // $2), "\n") if /^✘ Test (?:"(.*)"|(\S+)) failed after/;
			' "$log" | sort -u)

		# Never report green when the run itself failed.
		if [ $parsed -eq 0 ] && grep -q '^\*\* TEST FAILED \*\*' "$log"; then
			errors+="$layer on $platform: run failed but no failing test could be parsed (log: ${log#$REPO_ROOT/})"$'\n'
		fi

		# A crash or hang makes xcodebuild relaunch and still print "passed", dropping the test that died.
		if grep -q 'Restarting after unexpected exit, crash, or test timeout' "$log"; then
			errors+="$layer on $platform: the test host crashed or timed out and was restarted (log: ${log#$REPO_ROOT/})"$'\n'
		fi
		while IFS= read -r name; do
			[ -z "$name" ] && continue
			errors+="$layer on $platform: \"$name\" started but never finished"$'\n'
		done < <(perl -CSD -Mutf8 -ne '
				s/\x{200B}//g;
				if (/^◇ Test "(.*)" started\./) { $started{$1} = 1 }
				elsif (/^\S+ Test "(.*?)"(?: with \d+ test cases?)? (passed|failed|skipped)/) { $done{$1} = 1 }
				END { print "$_\n" for grep { !$done{$_} } sort keys %started }
			' "$log")
	done
done

status=0
if [ -n "$errors" ]; then
	echo "RUN ERRORS"; printf '%s' "$errors"; echo; status=2
fi
if [ -n "$broken" ]; then
	echo "BROKEN BEHAVIORS"; printf '%s' "$broken" | sort; echo; [ $status -eq 0 ] && status=1
fi
if [ -n "$unmapped" ]; then
	echo "FAILING TESTS WITHOUT A BEHAVIOR ID"; printf '%s' "$unmapped" | sort; echo; [ $status -eq 0 ] && status=1
fi
[ $status -eq 0 ] && echo "all green (${destinations[*]}; layers: $LAYERS)"
exit $status
