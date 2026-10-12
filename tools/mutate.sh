#!/usr/bin/env bash
# Proves a behavior's test can fail.
#
#   tools/mutate.sh ED-010 [ED-011 ...]
#
# For each ID: applies planning/behaviors/mutations/<ID>.patch (a small change to
# production code that breaks the behavior), runs only that behavior's test on Mac,
# and reverts the patch, even if interrupted.
#
# Result per ID:
#   KILLED    the test failed under the mutation (good)
#   SURVIVED  the test still passed (the test is too weak)
#   BROKEN    the mutation didn't compile or the test didn't run (fix the patch)
#
# Exit status is 0 only if every ID was KILLED.

set -uo pipefail
source "$(dirname "$0")/behavior-common.sh"

[ $# -gt 0 ] || { echo "usage: tools/mutate.sh ID [ID ...]" >&2; exit 2; }

applied_patch=""
revert() {
	if [ -n "$applied_patch" ]; then
		git -C "$REPO_ROOT" apply --whitespace=nowarn -R "$applied_patch" || echo "!! Could not revert $applied_patch; fix the working tree by hand." >&2
		applied_patch=""
	fi
}
trap revert EXIT
trap 'revert; exit 130' INT TERM

all_killed=0
for id in "$@"; do
	row="$(inventory_row "$id")"
	if [ -z "$row" ]; then
		echo "$id  BROKEN    not in BEHAVIORS.md"; all_killed=1; continue
	fi
	layer="$(inventory_field "$row" 3)"
	test_ref="$(inventory_field "$row" 4)"
	patch="$MUTATIONS_DIR/$id.patch"
	scheme="$(scheme_for_layer "$layer")" || { echo "$id  BROKEN    unknown layer '$layer'"; all_killed=1; continue; }

	if [ ! -f "$patch" ]; then
		echo "$id  BROKEN    no mutation patch at ${patch#$REPO_ROOT/}"; all_killed=1; continue
	fi
	if ! git -C "$REPO_ROOT" apply --whitespace=nowarn --check "$patch" 2>/dev/null; then
		echo "$id  BROKEN    patch does not apply to the current tree"; all_killed=1; continue
	fi

	git -C "$REPO_ROOT" apply --whitespace=nowarn "$patch" && applied_patch="$patch"
	output="$(run_tests "$scheme" "$MAC_DESTINATION" "-only-testing:$scheme/$test_ref")"
	revert

	log="$DERIVED_DATA/mutate-$id.log"
	mkdir -p "$DERIVED_DATA" && printf '%s\n' "$output" > "$log"

	# Search the file, not a pipe: grep -q exits early and pipefail would turn that into "no match".
	if grep -qE "✘ Test \"$id .*\" (failed|recorded an issue)" "$log"; then
		echo "$id  KILLED"
	elif grep -qE "(✔|━) Test \"$id .*\" passed" "$log"; then
		echo "$id  SURVIVED  test passed with the behavior broken"; all_killed=1
	else
		echo "$id  BROKEN    build failed or test didn't run (log: ${log#$REPO_ROOT/})"; all_killed=1
	fi
done

exit $all_killed
