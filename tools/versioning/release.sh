#!/bin/sh
set -eu

version=${1:-}
if [ -z "$version" ]; then
    printf '%s\n' 'Usage: make release VERSION=<MAJOR.MINOR.PATCH|patch|minor|major>' >&2
    exit 2
fi

CDPATH= cd -- "$(dirname -- "$0")/../.."
bump_my_version=${BUMP_MY_VERSION:-bump-my-version}
git_cliff=${GIT_CLIFF:-git-cliff}
github_cli=${GH:-gh}
make_command=${SDK_RELEASE_MAKE:-make}

version_header=lib/common/include/zx/version.h
bump_config=tools/versioning/bumpversion.toml
changelog=CHANGELOG.md

read_sdk_version() {
    awk '/^#define ZXEVO_SDK_VERSION_/ { printf "%s%s", separator, $3; separator = "." }'
}

case "$version" in
    patch|minor|major)
        version=$("$bump_my_version" show --config-file "$bump_config" \
            --increment "$version" new_version)
        ;;
esac
printf 'Release version %s\n' "$version"

branch=$(git symbolic-ref HEAD)
remote=$(git remote get-url --push origin)
repository=$("$github_cli" repo view "$remote" --json url --jq .url)
tag="v$version"
ref="refs/tags/$tag"

commit=$(git rev-parse HEAD)
if ! git show-ref --verify --quiet "$ref"; then
    if [ -n "$(git status --porcelain)" ]; then
        printf '%s\n' 'Commit local changes before preparing the release.' >&2
        exit 1
    fi
    git cat-file -e "$commit:$version_header"
    git cat-file -e "$commit:$bump_config"

    release_log=$(mktemp "${TMPDIR:-/tmp}/zxevo-changelog.XXXXXX")
    trap 'rm -f -- "$release_log"' EXIT
    "$git_cliff" --config tools/versioning/cliff.toml --use-branch-tags --tag "$tag" --output "$release_log"

    current=$("$bump_my_version" show --config-file "$bump_config" current_version)
    "$make_command" --no-print-directory -j1 format
    if [ "$version" != "$current" ]; then
        # The worktree was clean before formatting.
        "$bump_my_version" bump --config-file "$bump_config" --allow-dirty \
            --no-commit --no-tag --new-version "$version"
    fi
    if [ "$(read_sdk_version < "$version_header")" != "$version" ]; then
        printf '%s\n' "$version_header must contain SDK version $version" >&2
        exit 1
    fi

    cp "$release_log" "$changelog"
    git add --update
    git add -- "$changelog"
    if ! git diff --cached --quiet; then
        git commit -m "chore(release): release $version"
    fi
    commit=$(git rev-parse HEAD)
fi

committed=$(git show "$commit:$version_header" | read_sdk_version)
if [ "$committed" != "$version" ]; then
    printf '%s\n' "HEAD must contain SDK version $version" >&2
    exit 1
fi

if ! git show-ref --verify --quiet "$ref"; then
    git tag -a "$tag" -m "$tag" "$commit"
fi
if [ "$(git rev-parse "$ref^{commit}")" != "$commit" ]; then
    printf '%s\n' "$tag points to a different commit" >&2
    exit 1
fi

git push --atomic --no-follow-tags -- "$remote" "$commit:$branch" "$ref"
if published=$("$github_cli" release view "$tag" --repo "$repository" --json isDraft,url \
    --jq 'select(.isDraft | not).url' 2>/dev/null) && [ -n "$published" ]; then
    printf '%s\n' "$published"
else
    tagged_changelog=$(git show "$commit:$changelog")
    notes=$(printf '%s\n' "$tagged_changelog" | awk -v heading="## $tag" '
        $0 == heading { in_release = 1; next }
        in_release && /^## / { exit }
        in_release { print }
    ')
    {
        if [ -n "$notes" ]; then
            printf '%s\n\n' "$notes"
        fi
        printf '[Full changelog](%s/blob/%s/%s)\n' "$repository" "$tag" "$changelog"
    } | "$github_cli" release create "$tag" --repo "$repository" --verify-tag --notes-file -
fi
