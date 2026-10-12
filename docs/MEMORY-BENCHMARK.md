# Idle-memory and boot-time baseline

The Tokyo target is **under 1024 MiB** of host memory in use at idle; **850 MiB** is a development target. These are targets, not current verified results. A memory number is not a pass unless the desktop remains usable and security, graphics acceleration, and service behavior remain intact.

## Comparable test conditions

For each 4 GiB, 8 GiB, and 16 GiB profile:

1. Use the same image revision, machine type, vCPU count, graphics device, and kernel parameters. In QEMU, use the same virtual hardware except for RAM size.
2. Cold boot the installed system at least three times per profile. Do not use suspend/resume as a cold boot.
3. Use one 1920×1080 display, the same enabled autostart features, connected networking, and no user applications. Keep Waydroid and all VMs stopped for the idle baseline.
4. Start the measurement tool from the desktop session. It records samples at 5, 30, and 60 minutes since boot; if a target time has already passed, it records immediately and includes the actual uptime in the CSV.
5. Record the image/revision, GPU or QEMU display configuration, test-run number, and any deviations alongside the CSV.

## Capture

```sh
./tools/measure-idle-memory --output results/idle-4g-run1.csv
```

The tool writes a CSV and a matching `.metadata.txt` file. It refuses to overwrite either output. `--samples 5,30,60` is the default; a shorter smoke capture can use `--samples 0`.

The CSV includes:

- `mem_used_mib`: primary metric, `MemTotal - MemAvailable` from `/proc/meminfo`.
- `system_pss_mib`: sum of readable process `smaps_rollup` PSS values. Access restrictions may make this incomplete; it is not interchangeable with the primary metric.
- Niri and Noctalia process PSS, when readable.
- swap use, zram original/compressed data sizes, and `zram_mem_used_mib` (`mm_stat` field 3, actual zram RAM footprint; see the [Linux zram documentation](https://docs.kernel.org/admin-guide/blockdev/zram.html)), plus memory PSI `some avg10` pressure.
- sample uptime, so delayed command launch is visible.

The metadata sidecar records the session identity and `systemd-analyze time` output when available. Confirm and record the display mode/count, GPU/UMA memory behavior and cold-boot number manually; those are hardware/driver-dependent and the script does not infer that these test conditions were met.

## Reporting

Publish raw samples for every cold boot, not only the best run. Report the median and range at 5/30/60 minutes, plus boot timing. Note swap/zram activity and any PSI pressure. Do not flush caches, count swapped-out pages as reclaimed success, or exclude system services to produce a lower number.

Measure Waydroid and VM workloads separately as on-demand resource profiles; guest memory is excluded from the idle target but total host-plus-guest usage must be recorded for workload tests. If a profile misses the target, record it as unmet and investigate before removing required or security-sensitive components.
