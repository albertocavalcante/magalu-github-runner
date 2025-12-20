#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# cleanup-orphans.sh
#
# Cleans up orphaned Magalu Cloud resources that may be left behind after
# Terraform destroys. This includes:
#   - Public IPs with port_id = null (not attached to any VM)
#   - SSH Keys (optional, with --ssh-keys flag)
#   - VMs (optional, with --vms flag)
#
# Usage:
#   ./scripts/cleanup-orphans.sh [OPTIONS]
#
# Options:
#   --region REGION     Target region (default: br-ne1)
#   --dry-run           Show what would be deleted without deleting (default)
#   --execute           Actually delete the resources
#   --ssh-keys          Also clean up orphaned SSH keys
#   --vms               Also clean up VMs (DANGEROUS)
#   --help              Show this help message
#
# Examples:
#   ./scripts/cleanup-orphans.sh --region br-ne1 --dry-run
#   ./scripts/cleanup-orphans.sh --region br-ne1 --execute
#   ./scripts/cleanup-orphans.sh --execute --ssh-keys
# -----------------------------------------------------------------------------

set -euo pipefail

# Defaults
REGION="br-ne1"
DRY_RUN=true
CLEAN_SSH_KEYS=false
CLEAN_VMS=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

usage() {
  grep -E '^#' "$0" | tail -n +2 | sed 's/^# //' | sed 's/^#//'
  exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --region)
      REGION="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --execute)
      DRY_RUN=false
      shift
      ;;
    --ssh-keys)
      CLEAN_SSH_KEYS=true
      shift
      ;;
    --vms)
      CLEAN_VMS=true
      shift
      ;;
    --help|-h)
      usage
      ;;
    *)
      log_error "Unknown option: $1"
      usage
      ;;
  esac
done

echo "=============================================="
echo "  MGC Orphan Resource Cleanup"
echo "=============================================="
echo ""
log_info "Region:    $REGION"
log_info "Dry Run:   $DRY_RUN"
log_info "SSH Keys:  $CLEAN_SSH_KEYS"
log_info "VMs:       $CLEAN_VMS"
echo ""

if [[ "$DRY_RUN" == "true" ]]; then
  log_warn "DRY RUN MODE - No resources will be deleted"
  log_warn "Use --execute to actually delete resources"
  echo ""
fi

# Check if mgc CLI is available
if ! command -v mgc &> /dev/null; then
  log_error "mgc CLI not found. Please install it first."
  exit 1
fi

# Check if jq is available
if ! command -v jq &> /dev/null; then
  log_error "jq not found. Please install it first."
  exit 1
fi

# -----------------------------------------------------------------------------
# Clean up orphaned Public IPs (port_id = null)
# -----------------------------------------------------------------------------
echo "----------------------------------------------"
log_info "Checking for orphaned Public IPs..."
echo ""

orphaned_ips=$(mgc network public-ips list --region "$REGION" -o json --raw 2>/dev/null \
  | jq -r '.public_ips[] | select(.port_id == null) | "\(.id)|\(.public_ip)"' || echo "")

if [[ -z "$orphaned_ips" ]]; then
  log_success "No orphaned Public IPs found"
else
  orphan_count=$(echo "$orphaned_ips" | wc -l | tr -d ' ')
  log_warn "Found $orphan_count orphaned Public IP(s):"
  echo ""

  echo "$orphaned_ips" | while IFS='|' read -r id ip; do
    echo "  - $ip (ID: $id)"
  done
  echo ""

  if [[ "$DRY_RUN" == "false" ]]; then
    log_info "Deleting orphaned Public IPs..."
    echo "$orphaned_ips" | while IFS='|' read -r id ip; do
      log_info "  Deleting $ip ($id)..."
      if mgc network public-ips delete "$id" --region "$REGION" --no-confirm 2>&1; then
        log_success "  Deleted $ip"
      else
        log_error "  Failed to delete $ip"
      fi
    done
  fi
fi

# -----------------------------------------------------------------------------
# Clean up SSH Keys (optional)
# -----------------------------------------------------------------------------
if [[ "$CLEAN_SSH_KEYS" == "true" ]]; then
  echo ""
  echo "----------------------------------------------"
  log_info "Checking for SSH Keys..."
  echo ""

  ssh_keys=$(mgc profile ssh-keys list -o json --raw 2>/dev/null \
    | jq -r '.results[] | "\(.id)|\(.name)"' || echo "")

  if [[ -z "$ssh_keys" ]]; then
    log_success "No SSH keys found"
  else
    key_count=$(echo "$ssh_keys" | wc -l | tr -d ' ')
    log_warn "Found $key_count SSH key(s):"
    echo ""

    echo "$ssh_keys" | while IFS='|' read -r id name; do
      echo "  - $name (ID: $id)"
    done
    echo ""

    if [[ "$DRY_RUN" == "false" ]]; then
      log_info "Deleting SSH keys..."
      echo "$ssh_keys" | while IFS='|' read -r id name; do
        log_info "  Deleting $name ($id)..."
        if mgc profile ssh-keys delete "$id" --no-confirm 2>&1; then
          log_success "  Deleted $name"
        else
          log_error "  Failed to delete $name"
        fi
      done
    fi
  fi
fi

# -----------------------------------------------------------------------------
# Clean up VMs (optional, DANGEROUS)
# -----------------------------------------------------------------------------
if [[ "$CLEAN_VMS" == "true" ]]; then
  echo ""
  echo "----------------------------------------------"
  log_warn "Checking for VMs (DANGEROUS OPERATION)..."
  echo ""

  vms=$(mgc virtual-machine instances list --region "$REGION" -o json --raw 2>/dev/null \
    | jq -r '.instances[] | "\(.id)|\(.name)"' || echo "")

  if [[ -z "$vms" ]]; then
    log_success "No VMs found"
  else
    vm_count=$(echo "$vms" | wc -l | tr -d ' ')
    log_warn "Found $vm_count VM(s):"
    echo ""

    echo "$vms" | while IFS='|' read -r id name; do
      echo "  - $name (ID: $id)"
    done
    echo ""

    if [[ "$DRY_RUN" == "false" ]]; then
      log_warn "Deleting VMs..."
      echo "$vms" | while IFS='|' read -r id name; do
        log_info "  Deleting $name ($id)..."
        if mgc virtual-machine instances delete "$id" --region "$REGION" --no-confirm 2>&1; then
          log_success "  Deleted $name"
        else
          log_error "  Failed to delete $name"
        fi
      done
    fi
  fi
fi

echo ""
echo "----------------------------------------------"
if [[ "$DRY_RUN" == "true" ]]; then
  log_info "Dry run complete. Use --execute to perform actual cleanup."
else
  log_success "Cleanup complete!"
fi
echo ""
