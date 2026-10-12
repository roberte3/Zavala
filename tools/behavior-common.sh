# Shared settings for the behavior suite scripts. Sourced, not executed.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
BEHAVIORS_FILE="$REPO_ROOT/planning/behaviors/BEHAVIORS.md"
MUTATIONS_DIR="$REPO_ROOT/planning/behaviors/mutations"

# xcode-select may point at the Command Line Tools, which can't run these tests.
: "${DEVELOPER_DIR:=/Applications/Xcode-beta.app/Contents/Developer}"
export DEVELOPER_DIR

: "${DERIVED_DATA:=$REPO_ROOT/build/behavior-dd}"
: "${MAC_DESTINATION:=platform=macOS,variant=Mac Catalyst}"
: "${IPAD_DESTINATION:=platform=iOS Simulator,name=iPad Pro 11-inch (M5)}"

# Layer → scheme / test bundle name.
scheme_for_layer() {
	case "$1" in
		L1) echo "VinOutlineKitTests" ;;
		L2) echo "ZavalaTests" ;;
		L3) echo "ZavalaUITests" ;;
		*) return 1 ;;
	esac
}

# Prints the inventory table row for an ID (columns: ID, Behavior, Layer, Test, Status).
inventory_row() {
	grep -E "^\| $1 \|" "$BEHAVIORS_FILE" | head -1
}

# Field N (1-based) of an inventory row, trimmed.
inventory_field() {
	echo "$1" | awk -F'|' -v n="$(( $2 + 1 ))" '{ gsub(/^ +| +$/, "", $n); print $n }'
}

run_tests() { # scheme destination [extra xcodebuild args...]
	local scheme="$1" destination="$2"
	shift 2
	# The UI test runner must be signed with a development certificate (macOS kills an unsigned or ad-hoc one),
	# so L3 builds signed, in its own build folder so it doesn't force the unsigned L1/L2 builds to start over.
	local signing=(CODE_SIGNING_ALLOWED=NO) derived_data="$DERIVED_DATA"
	if [ "$scheme" = "ZavalaUITests" ]; then
		signing=(-allowProvisioningUpdates) derived_data="$DERIVED_DATA-signed"
	fi
	xcodebuild test \
		-project "$REPO_ROOT/Zavala.xcodeproj" \
		-scheme "$scheme" \
		-destination "$destination" \
		-derivedDataPath "$derived_data" \
		"${signing[@]}" \
		"$@" 2>&1
}

# Prints compile errors and Swift Testing results from an xcodebuild log, without build or system noise.
test_results() { # log
	perl -CSD -Mutf8 -ne '
		s/\x{200B}//g;
		if (/^\S.*\.swift:\d+:\d+: error: /) { print; next }
		$on = 1 if /^◇ Test run started/;
		next unless $on;
		next if /^\d{4}-\d\d-\d\d / || /^(◇|↳ Test(ing Library| Run| Target)|↳ Target Platform)/;
		print if /^(✘|✔|━|↳|  )/ || /^\*\* TEST/;
	' "$1"
}
