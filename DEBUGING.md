
# Debugging Guide

## Overview
Documentation for troubleshooting DevBox v1.0 setup issues.

## Exit Codes

| Code | Issue | Action |
|------|-------|--------|
| 1 | No root permission | Run with `sudo` |
| 2 | Missing argument | Use `--install` or `--doctor` |
| 3 | Invalid argument | Check command syntax |
| 4 | Library loading failed | Verify `lib/` files exist |
| 5 | apt installation failed | Check internet connection and apt cache |
| 6 | Docker installation failed | Review apt logs |
| 7 | Docker service start failed | Check system resources |
| 8 | Docker group setup failed | Verify user permissions |
| 9 | Docker Compose installation failed | Check Docker installation |
| 10 | Docker setup verification failed | Run `docker --version` |

## Common Issues

### Libraries Not Found
- Ensure all files in `lib/` directory exist
- Check file permissions: `ls -la lib/`
- Verify sourcing paths are relative to script location

### Log File Not Created
- Check `logs/` directory exists and is writable
- Verify logging.sh is properly sourced first
