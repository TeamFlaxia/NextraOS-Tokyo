import ast
import importlib.util
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import types
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]


class ProjectPolicyTests(unittest.TestCase):
    def read(self, relative_path: str) -> str:
        return (ROOT / relative_path).read_text(encoding="utf-8")

    def test_waydroid_initialization_is_not_enabled_for_boot(self):
        for relative_path in (
            "config/includes.chroot/etc/systemd/system/waydroid-init.service",
            "config/includes.chroot/etc/systemd/system/waydroid-binderfs.service",
        ):
            with self.subTest(unit=relative_path):
                unit = self.read(relative_path)
                self.assertNotIn("WantedBy=multi-user.target", unit)

        hook = self.read("config/hooks/live/0130-nextraos-waydroid-setup.hook.chroot")
        self.assertIn("systemctl --root=/ disable waydroid-container.service", hook)
        self.assertNotIn("systemctl enable waydroid-init.service", hook)
        self.assertNotIn("systemctl enable waydroid-binderfs.service", hook)

    def test_waydroid_init_requires_installer_selection(self):
        init_script = self.read(
            "config/includes.chroot/usr/local/bin/waydroid-init.sh"
        )
        selection_guard = 'if [ ! -f "$SYSTEM_TYPE_FILE" ]; then'
        self.assertIn(selection_guard, init_script)
        self.assertLess(init_script.index(selection_guard), init_script.index("waydroid init"))
        self.assertNotIn('WAYDROID_SYSTEM_TYPE="VANILLA"', init_script)

    def test_waydroid_initializes_as_container_dependency(self):
        dropin = self.read(
            "config/includes.chroot/etc/systemd/system/"
            "waydroid-container.service.d/10-nextraos-init.conf"
        )
        self.assertIn("Requires=waydroid-init.service", dropin)
        self.assertIn("After=waydroid-init.service", dropin)

        init_unit = self.read(
            "config/includes.chroot/etc/systemd/system/waydroid-init.service"
        )
        self.assertIn("Requires=waydroid-binderfs.service", init_unit)
        self.assertIn("After=network-online.target", init_unit)

    def test_installer_disables_waydroid_boot_activation_on_target(self):
        source = self.read(
            "config/includes.chroot/usr/lib/calamares/modules/"
            "nextraos-postinstall/main.py"
        )
        ast.parse(source)
        run_start = source.index("def run():")
        run_end = source.index("def _disable_waydroid_boot_activation")
        run_body = source[run_start:run_end]
        self.assertIn("_disable_waydroid_boot_activation()", run_body)
        self.assertLess(
            run_body.index("_disable_waydroid_boot_activation()"),
            run_body.index("selections ="),
        )
        self.assertIn('"--root=" + root', source)
        self.assertIn('root == os.path.abspath(os.sep)', source)
        self.assertIn('"disable", "waydroid-container.service"', source)

    @unittest.skipUnless(shutil.which("systemctl"), "systemctl is unavailable")
    def test_calamares_disables_waydroid_boot_link_in_target_root(self):
        with tempfile.TemporaryDirectory(
            prefix="nextraos-calamares-test-", dir=ROOT
        ) as temp:
            target = Path(temp) / "target"
            unit_dir = target / "usr/lib/systemd/system"
            wants_dir = target / "etc/systemd/system/multi-user.target.wants"
            unit_dir.mkdir(parents=True)
            wants_dir.mkdir(parents=True)
            (unit_dir / "waydroid-container.service").write_text(
                "[Unit]\nDescription=Test Waydroid service\n"
                "[Service]\nExecStart=/bin/true\n"
                "[Install]\nWantedBy=multi-user.target\n",
                encoding="utf-8",
            )
            boot_link = wants_dir / "waydroid-container.service"
            boot_link.symlink_to(
                "/usr/lib/systemd/system/waydroid-container.service"
            )

            calamares = types.ModuleType("libcalamares")
            calamares.globalstorage = types.SimpleNamespace(
                value=lambda key: str(target) if key == "rootMountPoint" else None
            )
            calamares.utils = types.SimpleNamespace(warning=lambda _message: None)
            with patch.dict(sys.modules, {"libcalamares": calamares}):
                module_path = ROOT / (
                    "config/includes.chroot/usr/lib/calamares/modules/"
                    "nextraos-postinstall/main.py"
                )
                spec = importlib.util.spec_from_file_location(
                    "nextraos_postinstall_test", module_path
                )
                module = importlib.util.module_from_spec(spec)
                spec.loader.exec_module(module)
                module._disable_waydroid_boot_activation()
                module._disable_waydroid_boot_activation()

            self.assertFalse(boot_link.is_symlink())

    def test_memory_collector_reports_zram_ram_footprint(self):
        collector = self.read("tools/measure-idle-memory")
        self.assertIn("zram_used=$(zram_bytes 3)", collector)
        self.assertIn("zram_mem_used_mib", collector)

    def test_niri_package_scaffold_is_pinned_and_not_integrated(self):
        builder = self.read("tools/build-niri-package")
        self.assertIn("8ed0da44d974c32c6877d2f4630c314da0717ecb", builder)
        self.assertIn("cargo vendor --locked", builder)
        self.assertIn("VERSION_CODENAME", builder)

        control = self.read("packages/nextraos-niri/debian/control")
        self.assertIn("Architecture: amd64", control)
        self.assertIn("libwayland-server0", control)
        self.assertNotIn("xwayland-satellite", control)

        rules = self.read("packages/nextraos-niri/debian/rules")
        self.assertIn("cargo build --frozen --release --package niri", rules)
        self.assertIn(
            "NIRI_BUILD_COMMIT = 8ed0da44d974c32c6877d2f4630c314da0717ecb",
            rules,
        )
        self.assertNotIn("--all-features", rules)
        assets = self.read("packages/nextraos-niri/debian/nextraos-niri.install")
        for asset in (
            "usr/bin/niri-session",
            "usr/share/wayland-sessions/niri.desktop",
            "usr/share/xdg-desktop-portal/niri-portals.conf",
            "usr/lib/systemd/user/niri.service",
            "usr/lib/systemd/user/niri-shutdown.target",
        ):
            with self.subTest(asset=asset):
                self.assertIn(asset, assets)

        desktop_packages = self.read("config/package-lists/desktop.list.chroot")
        self.assertNotIn("nextraos-niri", desktop_packages)
        self.assertIn("live-task-kde", desktop_packages)

    def test_noctalia_pin_has_fingerprint_hash_and_disposable_test(self):
        verifier = self.read("tools/test-noctalia-package")
        self.assertIn("5.2.1-1+deb13u1", verifier)
        self.assertIn(
            "63a0aa02fab9c83edaf0c3a063bb3c3079c7ea3673fa37c8ff18d47c5cae02f7",
            verifier,
        )
        self.assertIn("C2A7E07FB3D746BDF2A245CD683B67D7BC99A9B7", verifier)
        self.assertIn("debian:trixie", verifier)
        self.assertIn("apt-get -qq update", verifier)
        self.assertIn("noctalia config validate", verifier)
        self.assertIn("/noctalia-config.toml:ro", verifier)

        config = self.read("packages/nextraos-niri/noctalia-config.toml")
        self.assertIn("telemetry_enabled = false", config)
        self.assertIn("external_ip_enabled = false", config)
        self.assertIn('key_source = "secret-service"', config)
        self.assertIn("polkit_agent = true", config)
        self.assertIn("screen_time_enabled = false", config)
        self.assertIn("fetch_exchange_rates = false", config)

    def test_niri_test_iso_is_reversible_and_minimal(self):
        builder = self.read("build/build-niri-test-iso")
        profile = self.read("build/profiles/niri-test/desktop.list.chroot")
        archive = self.read("build/profiles/niri-test/noctalia.list.chroot")
        greeter = self.read("build/profiles/niri-test/greetd-config.toml")
        greeter_user = self.read("build/profiles/niri-test/greetd-user.hook.chroot")
        noctalia_unit = self.read("build/profiles/niri-test/noctalia.service")
        historical_desktop = self.read("config/package-lists/desktop.list.chroot")
        root_auto_config = self.read("auto/config")

        self.assertIn("disposable copy", builder)
        self.assertNotIn("noautologin", root_auto_config)
        self.assertIn('--debootstrap-options "--include=ca-certificates"', builder)
        self.assertIn("--apt-recommends false", builder)
        self.assertIn("sudo lb build", builder)
        self.assertIn("Refusing to overwrite existing ISO or symlink", builder)
        self.assertIn('[[ ! -e "$ISO_OUT" && ! -L "$ISO_OUT" ]]', builder)
        self.assertIn("noautologin", builder)
        self.assertIn("console=ttyS0", builder)
        self.assertIn('cp -- "${ISO_FILES[0]}" "$ISO_TEMP"', builder)
        self.assertIn('mv -nT -- "$ISO_TEMP" "$ISO_OUT"', builder)
        self.assertIn("NOCTALIA_FINGERPRINT", builder)
        self.assertIn("noctalia.key.chroot", builder)
        self.assertIn("noctalia.pref.chroot", builder)
        self.assertIn("nextraos-niri_26.04-1_amd64.deb", builder)
        self.assertIn("nextraos-niri=26.04-1", profile)
        self.assertIn("noctalia=5.2.1-1+deb13u1", profile)
        self.assertIn("greetd", profile)
        self.assertIn("tuigreet", profile)
        self.assertIn("user-setup", profile)
        self.assertIn("greetd-user.hook.chroot", builder)
        self.assertIn('"$PROFILE_DIR/noctalia.service"', builder)
        self.assertIn("/usr/lib/systemd/user/noctalia.service", builder)
        self.assertIn("adduser --system --group", greeter_user)
        self.assertIn("greeter", greeter_user)
        self.assertIn("BindsTo=niri.service", noctalia_unit)
        self.assertIn("After=niri.service", noctalia_unit)
        self.assertIn("PartOf=niri.service", noctalia_unit)
        self.assertIn("ExecStart=/usr/bin/noctalia", noctalia_unit)
        self.assertIn("Restart=on-failure", noctalia_unit)
        self.assertIn("TimeoutStopSec=5s", noctalia_unit)
        self.assertIn("gnome-keyring", profile)
        self.assertIn("libpam-gnome-keyring", profile)
        self.assertIn("xdg-desktop-portal-gnome", profile)
        self.assertIn("ca-certificates", profile)
        self.assertNotIn("task-kde-desktop", profile)
        self.assertNotIn("waydroid", profile)
        self.assertIn("signed-by=/etc/apt/trusted.gpg.d/noctalia.key.chroot.gpg", archive)
        self.assertIn("tuigreet --time --sessions /usr/share/wayland-sessions", greeter)
        self.assertIn("vt = 7", greeter)
        self.assertIn("live-task-kde", historical_desktop)
        self.assertIn("task-kde-desktop", historical_desktop)

    def test_niri_config_starts_bound_noctalia_unit_and_uses_documented_ipc(self):
        config = self.read("packages/nextraos-niri/nextraos-config.kdl")
        self.assertIn(
            'spawn-at-startup "systemctl" "--user" "start" "noctalia.service"',
            config,
        )
        self.assertNotIn('spawn-at-startup "noctalia"', config)
        self.assertIn('noctalia msg panel-toggle launcher', config)
        self.assertIn('noctalia msg panel-toggle control-center', config)
        self.assertIn('spawn "foot"', config)
        self.assertNotIn('spawn-at-startup "waybar"', config)

    def test_iso_publish_no_clobber_preserves_dangling_symlink(self):
        with tempfile.TemporaryDirectory(prefix="nextraos-iso-publish-", dir=ROOT) as temp:
            temp_path = Path(temp)
            staged_iso = temp_path / "staged.iso"
            dangling_target = temp_path / "outside.iso"
            output_iso = temp_path / "nextraos.iso"
            staged_iso.write_bytes(b"test ISO")
            output_iso.symlink_to(dangling_target)

            subprocess.run(
                ["mv", "-nT", str(staged_iso), str(output_iso)],
                check=True,
                capture_output=True,
                text=True,
            )

            self.assertTrue(staged_iso.is_file())
            self.assertTrue(output_iso.is_symlink())
            self.assertFalse(dangling_target.exists())

    def test_qemu_runner_requests_gl_for_compositor_tests(self):
        runner = self.read("tools/run-qemu")
        self.assertIn("nextraos_qemu", runner)
        self.assertIn("nextraos_create_ovmf_vars_copy", runner)
        self.assertIn('file="$OVMF_VARS_COPY"', runner)
        self.assertNotIn('file="$OVMF_VARS"', runner)
        install_runner = self.read("tools/run-qemu-install")
        self.assertIn("nextraos_create_ovmf_vars_copy", install_runner)
        self.assertIn('file="$OVMF_VARS_COPY"', install_runner)
        self.assertIn("dist/*.qcow2", self.read(".gitignore"))
        self.assertIn('exec "$SCRIPT_DIR/run-qemu-bios" "$ISO_FILE" "$@"', runner)
        self.assertIn("ISO_FILE=$1\n    shift", runner)
        bios_runner = self.read("tools/run-qemu-bios")
        install_runner = self.read("tools/run-qemu-install")
        self.assertIn("UEFI firmware is required", install_runner)
        self.assertNotIn('exec "$0" --bios', install_runner)
        self.assertLess(
            install_runner.index('if [ ! -f "$OVMF_CODE"'),
            install_runner.index('qemu-img create'),
        )
        for content in (runner, bios_runner, install_runner):
            with self.subTest(runner="QEMU script"):
                self.assertIn("nextraos_qemu", content)
                self.assertIn("-audiodev sdl,id=audio0", content)
                self.assertIn("-device intel-hda", content)
                self.assertIn("hda-duplex,audiodev=audio0", content)
                self.assertIn("ISO_FILE=$1\n    shift", content)
        common = self.read("tools/qemu-common.sh")
        self.assertIn("NEXTRAOS_QEMU_ACCEL=kvm", common)
        self.assertIn("NEXTRAOS_QEMU_ACCEL=tcg", common)
        self.assertIn("qemu-system-x86_64 -enable-kvm -cpu", common)
        self.assertIn("qemu-system-x86_64 -accel tcg,thread=multi -cpu", common)
        self.assertIn("NEXTRAOS_QEMU_GL=${NEXTRAOS_QEMU_GL:-1}", common)
        self.assertIn("NEXTRAOS_QEMU_DISPLAY=${NEXTRAOS_QEMU_DISPLAY:-sdl}", common)
        self.assertIn("virtio-vga-gl", common)
        self.assertIn("sdl,gl=on", common)
        self.assertIn("virtio-vga -display sdl,gl=off", common)
        self.assertIn("virtio-vga-gl -display gtk,gl=on", common)
        self.assertIn("virtio-vga -display gtk,gl=off", common)
        self.assertIn("-vga std -display gtk,gl=off", common)
        self.assertIn("virtio-vga -display none", common)

    def test_qemu_bios_fallback_preserves_iso_and_extra_args(self):
        with tempfile.TemporaryDirectory(
            prefix="nextraos-qemu-test-", dir=ROOT
        ) as temp:
            temp_path = Path(temp)
            tools_dir = temp_path / "tools"
            fake_bin = temp_path / "bin"
            tools_dir.mkdir()
            fake_bin.mkdir()

            runner_source = self.read("tools/run-qemu")
            runner_source = runner_source.replace(
                "/usr/share/OVMF/OVMF_CODE_4M.fd",
                str(temp_path / "missing/OVMF_CODE_4M.fd"),
            )
            (tools_dir / "run-qemu").write_text(runner_source, encoding="utf-8")
            (tools_dir / "run-qemu").chmod(0o755)
            shutil.copy2(ROOT / "tools/run-qemu-bios", tools_dir / "run-qemu-bios")
            shutil.copy2(ROOT / "tools/qemu-common.sh", tools_dir / "qemu-common.sh")

            fake_qemu = fake_bin / "qemu-system-x86_64"
            fake_qemu.write_text(
                "#!/bin/sh\n"
                "printf '%s\\n' \"$@\" > \"$QEMU_ARGS_FILE\"\n",
                encoding="utf-8",
            )
            fake_qemu.chmod(0o755)
            iso = temp_path / "custom.iso"
            iso.write_bytes(b"test iso")
            args_file = temp_path / "qemu-args.txt"
            env = os.environ.copy()
            env.pop("NEXTRAOS_QEMU_GL", None)
            env.pop("NEXTRAOS_QEMU_DISPLAY", None)
            env["PATH"] = str(fake_bin) + os.pathsep + env.get("PATH", "")
            env["QEMU_ARGS_FILE"] = str(args_file)
            kvm_device = temp_path / "kvm-device"
            env["NEXTRAOS_QEMU_KVM_DEVICE"] = str(kvm_device)

            subprocess.run(
                [str(tools_dir / "run-qemu"), str(iso), "-m", "8G"],
                check=True,
                env=env,
                capture_output=True,
                text=True,
            )
            args = args_file.read_text(encoding="utf-8").splitlines()
            self.assertIn(
                f"file={iso},format=raw,media=cdrom",
                args,
            )
            self.assertNotIn(str(iso), args)
            self.assertEqual(args[-6:-4], ["-m", "8G"])
            self.assertIn("virtio-vga-gl", args)
            self.assertIn("sdl,gl=on", args)
            self.assertIn("-accel", args)
            self.assertEqual(args[args.index("-accel") + 1], "tcg,thread=multi")
            self.assertEqual(args[args.index("-cpu") + 1], "max")

            kvm_device.touch()
            subprocess.run(
                [str(tools_dir / "run-qemu"), str(iso), "-m", "8G"],
                check=True,
                env=env,
                capture_output=True,
                text=True,
            )
            kvm_args = args_file.read_text(encoding="utf-8").splitlines()
            self.assertIn("-enable-kvm", kvm_args)
            self.assertEqual(kvm_args[kvm_args.index("-cpu") + 1], "host")

            env["NEXTRAOS_QEMU_GL"] = "0"
            subprocess.run(
                [str(tools_dir / "run-qemu"), str(iso)],
                check=True,
                env=env,
                capture_output=True,
                text=True,
            )
            software_args = args_file.read_text(encoding="utf-8").splitlines()
            self.assertIn("virtio-vga", software_args)
            self.assertIn("sdl,gl=off", software_args)
            self.assertNotIn("virtio-vga-gl", software_args)

            env["NEXTRAOS_QEMU_DISPLAY"] = "gtk"
            subprocess.run(
                [str(tools_dir / "run-qemu"), str(iso)],
                check=True,
                env=env,
                capture_output=True,
                text=True,
            )
            gtk_args = args_file.read_text(encoding="utf-8").splitlines()
            self.assertIn("virtio-vga", gtk_args)
            self.assertIn("gtk,gl=off", gtk_args)
            self.assertNotIn("virtio-vga-gl", gtk_args)

            env["NEXTRAOS_QEMU_GL"] = "1"
            subprocess.run(
                [str(tools_dir / "run-qemu"), str(iso)],
                check=True,
                env=env,
                capture_output=True,
                text=True,
            )
            gtk_gl_args = args_file.read_text(encoding="utf-8").splitlines()
            self.assertIn("virtio-vga-gl", gtk_gl_args)
            self.assertIn("gtk,gl=on", gtk_gl_args)

            env["NEXTRAOS_QEMU_DISPLAY"] = "gtk-std"
            subprocess.run(
                [str(tools_dir / "run-qemu"), str(iso)],
                check=True,
                env=env,
                capture_output=True,
                text=True,
            )
            std_args = args_file.read_text(encoding="utf-8").splitlines()
            self.assertIn("-vga", std_args)
            self.assertEqual(std_args[std_args.index("-vga") + 1], "std")
            self.assertIn("gtk,gl=off", std_args)
            self.assertNotIn("virtio-vga-gl", std_args)

            env["NEXTRAOS_QEMU_DISPLAY"] = "none"
            subprocess.run(
                [str(tools_dir / "run-qemu"), str(iso)],
                check=True,
                env=env,
                capture_output=True,
                text=True,
            )
            headless_args = args_file.read_text(encoding="utf-8").splitlines()
            self.assertIn("virtio-vga", headless_args)
            self.assertEqual(
                headless_args[headless_args.index("-display") + 1], "none"
            )
            self.assertNotIn("virtio-vga-gl", headless_args)

    def test_libvirt_setup_uses_local_socket_activation(self):
        paths = (
            "config/hooks/live/0140-nextraos-windows-vm-setup.hook.chroot",
            "config/hooks/live/0150-nextraos-macos-vm-setup.hook.chroot",
            "config/includes.chroot/usr/local/bin/nextraos-postinstall",
            "config/includes.chroot/usr/lib/calamares/modules/nextraos-postinstall/main.py",
        )
        for relative_path in paths:
            with self.subTest(script=relative_path):
                content = self.read(relative_path)
                self.assertIn("libvirtd.socket", content)
                self.assertNotIn("systemctl enable libvirtd.service", content)


if __name__ == "__main__":
    unittest.main()
