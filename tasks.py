from __future__ import annotations

import os
import shlex
from pathlib import Path

from invoke import task


ROOT = Path(__file__).resolve().parent
IOS_DIR = ROOT / "ios" / "TauberDefenceIOS"
DEFAULT_IPHONE = "iPhone 17 Pro"
DEFAULT_IPAD = "iPad Pro 13-inch (M5)"


def _ios_env() -> dict[str, str]:
    module_cache = IOS_DIR / ".clang-module-cache"
    module_cache.mkdir(parents=True, exist_ok=True)
    env = os.environ.copy()
    env.setdefault("DEVELOPER_DIR", "/Applications/Xcode.app/Contents/Developer")
    env.setdefault("CLANG_MODULE_CACHE_PATH", str(module_cache))
    return env


@task
def install_xcodegen(c) -> None:
    """Install XcodeGen through Homebrew when missing."""
    c.run(
        "brew list xcodegen >/dev/null 2>&1 || brew install xcodegen",
        pty=False,
        shell="/bin/bash",
    )


@task
def generate_ios_project(c) -> None:
    """Generate the ignored Xcode project from project.yml."""
    c.run(
        f"cd {shlex.quote(str(IOS_DIR))} && xcodegen generate",
        env=_ios_env(),
        pty=False,
        shell="/bin/bash",
    )


@task
def check_ios_package(c) -> None:
    """Run Swift package tests and the configured line-coverage gate."""
    c.run(
        shlex.quote(str(IOS_DIR / "Scripts" / "check_coverage.sh")),
        env=_ios_env(),
        pty=False,
        shell="/bin/bash",
    )


@task(
    help={
        "device_name": "Exact installed iOS Simulator device name.",
        "artifact_dir": "Repo-relative directory for logs and xcresult.",
        "only_testing": "XCTest target, class, or method selection.",
    }
)
def ios_ui_e2e(
    c,
    device_name=DEFAULT_IPHONE,
    artifact_dir="e2e-artifacts/ios-iphone",
    only_testing="TauberDefenceUITests",
) -> None:
    """Run serial, isolated XCUITest with configurable failed-test retries."""
    command = " ".join(
        [
            shlex.quote(str(IOS_DIR / "Scripts" / "run_ui_e2e.sh")),
            shlex.quote(device_name),
            shlex.quote(artifact_dir),
            shlex.quote(only_testing),
        ]
    )
    c.run(command, env=_ios_env(), pty=False, shell="/bin/bash")


@task(
    help={
        "device_name": "Exact installed iOS Simulator device name.",
        "artifact_dir": "Repo-relative directory for App Store PNGs and xcresult.",
    }
)
def ios_marketing_screenshots(
    c,
    device_name=DEFAULT_IPHONE,
    artifact_dir="e2e-artifacts/marketing-iphone",
) -> None:
    """Capture five deterministic App Store screenshots on one simulator."""
    ios_ui_e2e.body(
        c,
        device_name=device_name,
        artifact_dir=artifact_dir,
        only_testing=(
            "TauberDefenceUITests/TauberDefenceMarketingScreenshots/"
            "testAppStoreMarketingScreenshots"
        ),
    )


@task
def app_store_screenshots(c) -> None:
    """Capture the App Store gallery for the default iPhone and iPad."""
    install_xcodegen.body(c)
    ios_marketing_screenshots.body(
        c,
        device_name=DEFAULT_IPHONE,
        artifact_dir="e2e-artifacts/marketing-iphone",
    )
    ios_marketing_screenshots.body(
        c,
        device_name=DEFAULT_IPAD,
        artifact_dir="e2e-artifacts/marketing-ipad",
    )


@task(
    help={
        "device_name": "Exact installed iOS Simulator device name.",
        "configuration": "Xcode build configuration.",
    }
)
def build_ios_simulator(c, device_name=DEFAULT_IPHONE, configuration="Debug") -> None:
    """Generate and compile the app for one simulator without signing."""
    install_xcodegen.body(c)
    generate_ios_project.body(c)
    destination = f"platform=iOS Simulator,name={device_name},OS=latest"
    command = " ".join(
        [
            f"cd {shlex.quote(str(IOS_DIR))} &&",
            "xcodebuild",
            "-project TauberDefenceApp.xcodeproj",
            "-scheme TauberDefence",
            f"-configuration {shlex.quote(configuration)}",
            f"-destination {shlex.quote(destination)}",
            "-destination-timeout 120",
            "-derivedDataPath .derived-data",
            "CODE_SIGNING_ALLOWED=NO",
            "build",
        ]
    )
    c.run(command, env=_ios_env(), pty=False, shell="/bin/bash")


@task
def check_ios_ci(c) -> None:
    """Run the package, iPhone, and iPad gates used before TestFlight."""
    check_ios_package.body(c)
    install_xcodegen.body(c)
    ios_ui_e2e.body(
        c,
        device_name=DEFAULT_IPHONE,
        artifact_dir="e2e-artifacts/ios-iphone",
    )
    ios_ui_e2e.body(
        c,
        device_name=DEFAULT_IPAD,
        artifact_dir="e2e-artifacts/ios-ipad",
    )


@task(
    help={
        "marketing_version": "Three-part App Store version, for example 0.0.1.",
        "build_number": "Positive App Store build number.",
    }
)
def upload_testflight(c, marketing_version, build_number) -> None:
    """Archive, sign, and upload through the configured local Xcode account."""
    command = " ".join(
        [
            shlex.quote(str(IOS_DIR / "Scripts" / "upload_testflight.sh")),
            shlex.quote(marketing_version),
            shlex.quote(str(build_number)),
        ]
    )
    c.run(command, env=_ios_env(), pty=False, shell="/bin/bash")


@task(default=True)
def check(c) -> None:
    """Alias for the complete native CI gate."""
    check_ios_ci.body(c)
