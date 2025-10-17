
VERSION=0.20.0


ARCH_RAW="$(uname -m)"
case "$ARCH_RAW" in
  x86_64) ARCH=amd64 ;;
  aarch64|arm64) ARCH=arm64 ;;
  *) echo "Unsupported arch: $ARCH_RAW"; exit 1 ;;
esac


set -euo pipefail
TMP=/tmp/terraform-docs.tgz
URL="https://github.com/terraform-docs/terraform-docs/releases/download/v${VERSION}/terraform-docs-v${VERSION}-linux-${ARCH}.tar.gz"

echo "Downloading $URL"
curl -fsSL -o "$TMP" "$URL"


if ! file "$TMP" | grep -qi gzip; then
  echo "Download didn't look like a .tar.gz (bad VERSION/URL/arch?). First lines:"; head -n 20 "$TMP"; exit 1
fi

sudo tar -xzf "$TMP" -C /usr/local/bin terraform-docs
sudo chmod +x /usr/local/bin/terraform-docs

terraform-docs --version
