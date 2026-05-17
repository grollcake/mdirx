#!/usr/bin/env python3
"""Generate MdirX.xcodeproj/project.pbxproj by scanning source directories.

새 파일을 추가하면 이 스크립트만 다시 돌리면 자동으로 등록된다.
UID는 (namespace + 경로) SHA-1 해시 기반이라 같은 파일에는 같은 UID가 부여돼
diff가 안정적이다.

Source 디렉터리:
- App/                 → MdirX 타겟
- Core/                → MdirX 타겟
- Features/            → MdirX 타겟
- DesignSystem/        → MdirX 타겟
- Tests/UnitTests/     → MdirXTests 타겟
- Tests/UITests/       → MdirXUITests 타겟

리소스(Assets.xcassets, *.entitlements, Localization/*.lproj/Localizable.strings,
GeneratedAssetSymbols.swift), 타겟 설정·의존성·빌드 컨피그는 하단의
하드코딩 섹션을 유지.
"""
import hashlib
from pathlib import Path


def stable_uid(namespace: str, key: str) -> str:
    digest = hashlib.sha1(f"{namespace}::{key}".encode()).hexdigest()
    return digest[:24].upper()


ROOT = Path(__file__).resolve().parents[1]

APP_SOURCE_DIRS = ["App", "Core", "DesignSystem", "Features"]
UNIT_TEST_DIR = "Tests/UnitTests"
UI_TEST_DIR = "Tests/UITests"

# Stable UID 네임스페이스
NS_FR = "FR"              # PBXFileReference (per source file)
NS_BF_APP = "BF:app"      # MdirX 타겟 PBXBuildFile
NS_BF_TEST = "BF:test"    # MdirXTests 타겟 PBXBuildFile
NS_BF_UIT = "BF:uit"      # MdirXUITests 타겟 PBXBuildFile
NS_GROUP = "GROUP"        # PBXGroup (per directory)


# ─── 1) 디스크 스캔 ──────────────────────────────────────────────

def scan_swift_files(dirs: list[str]) -> list[Path]:
    files: list[Path] = []
    for d in dirs:
        base = ROOT / d
        if not base.exists():
            continue
        for path in sorted(base.rglob("*.swift")):
            if path.is_file():
                files.append(path.relative_to(ROOT))
    return files


app_files = scan_swift_files(APP_SOURCE_DIRS)
unit_test_files = scan_swift_files([UNIT_TEST_DIR])
ui_test_files = scan_swift_files([UI_TEST_DIR])

# 그룹 = 발견된 파일의 부모 디렉터리 전부 (최상위 ROOT는 제외)
group_dirs: set[Path] = set()
for f in app_files + unit_test_files + ui_test_files:
    p = f.parent
    while str(p) not in (".", ""):
        group_dirs.add(p)
        p = p.parent
group_dirs_sorted = sorted(group_dirs, key=lambda p: (len(p.parts), str(p)))


# ─── 2) UID ──────────────────────────────────────────────────────

def fr_uid(rel: Path) -> str:
    return stable_uid(NS_FR, str(rel))


def bf_uid(ns: str, rel: Path) -> str:
    return stable_uid(ns, str(rel))


def group_uid(rel: Path) -> str:
    return stable_uid(NS_GROUP, str(rel))


# 타겟/구성 등 하드코딩 UID (직접 해시로 stable 처리)
U = {k: stable_uid("PBX", k) for k in [
    "PROJECT", "MAIN_GRP", "PROD_GRP",
    "APP_GRP", "RES_GRP",
    "MDIRX_SUPP", "TPSRC", "UTPSRC",
    "APP_PROD", "TEST_PROD", "UITEST_PROD",
    "FR_ASSETS", "BF_ASSETS",
    "FR_ENT",
    "FR_EN", "FR_KO", "BF_EN", "BF_KO",
    "MTARGET", "TTARGET", "UTTARGET",
    "APSRC", "APRES", "APFRMWK", "BAA", "BAT", "BAB", "BAUT",
    "DEP", "DEPUT", "PROXY", "PROXYUT",
    "DBG_APP", "REL_APP", "DBG_TEST", "REL_TEST", "DBG_UIT", "REL_UIT",
    "DBG_PROJ", "REL_PROJ", "ACFG", "TCFG", "UTCFG", "PCFG",
]}


# ─── 3) 섹션 빌더 ────────────────────────────────────────────────

def comment(rel: Path) -> str:
    return rel.name


def build_file_lines() -> str:
    lines: list[str] = []
    for f in app_files:
        lines.append(
            f"\t\t{bf_uid(NS_BF_APP, f)} /* {comment(f)} in Sources */ "
            f"= {{isa = PBXBuildFile; fileRef = {fr_uid(f)}; }};"
        )
    for f in unit_test_files:
        lines.append(
            f"\t\t{bf_uid(NS_BF_TEST, f)} /* {comment(f)} in Sources */ "
            f"= {{isa = PBXBuildFile; fileRef = {fr_uid(f)}; }};"
        )
    for f in ui_test_files:
        lines.append(
            f"\t\t{bf_uid(NS_BF_UIT, f)} /* {comment(f)} in Sources */ "
            f"= {{isa = PBXBuildFile; fileRef = {fr_uid(f)}; }};"
        )
    # 리소스 build file
    lines.append(
        f"\t\t{U['BF_ASSETS']} /* Assets.xcassets in Resources */ "
        f"= {{isa = PBXBuildFile; fileRef = {U['FR_ASSETS']}; }};"
    )
    lines.append(
        f"\t\t{U['BF_EN']} /* en Localizable.strings in Resources */ "
        f"= {{isa = PBXBuildFile; fileRef = {U['FR_EN']}; }};"
    )
    lines.append(
        f"\t\t{U['BF_KO']} /* ko Localizable.strings in Resources */ "
        f"= {{isa = PBXBuildFile; fileRef = {U['FR_KO']}; }};"
    )
    return "\n".join(lines)


def file_reference_lines() -> str:
    lines: list[str] = []
    for f in app_files + unit_test_files + ui_test_files:
        lines.append(
            f"\t\t{fr_uid(f)} /* {comment(f)} */ "
            f"= {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; "
            f"path = {comment(f)}; sourceTree = \"<group>\"; }};"
        )
    # 리소스 / 산출물 / 엔타이틀먼트
    lines.append(
        f"\t\t{U['FR_ASSETS']} /* Assets.xcassets */ "
        f"= {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; "
        f"path = Resources/Assets.xcassets; sourceTree = \"<group>\"; }};"
    )
    lines.append(
        f"\t\t{U['FR_ENT']} /* MdirX.entitlements */ "
        f"= {{isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; "
        f"path = MdirX/MdirX.entitlements; sourceTree = \"<group>\"; }};"
    )
    lines.append(
        f"\t\t{U['FR_EN']} /* en/Localizable.strings */ "
        f"= {{isa = PBXFileReference; lastKnownFileType = text.plist.strings; "
        f"name = Localizable.strings; path = Resources/Localization/en.lproj/Localizable.strings; "
        f"sourceTree = \"<group>\"; }};"
    )
    lines.append(
        f"\t\t{U['FR_KO']} /* ko/Localizable.strings */ "
        f"= {{isa = PBXFileReference; lastKnownFileType = text.plist.strings; "
        f"name = Localizable.strings; path = Resources/Localization/ko.lproj/Localizable.strings; "
        f"sourceTree = \"<group>\"; }};"
    )
    lines.append(
        f"\t\t{U['APP_PROD']} /* MdirX.app */ "
        f"= {{isa = PBXFileReference; explicitFileType = wrapper.application; "
        f"includeInIndex = 0; path = MdirX.app; sourceTree = BUILT_PRODUCTS_DIR; }};"
    )
    lines.append(
        f"\t\t{U['TEST_PROD']} /* MdirXTests.xctest */ "
        f"= {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; "
        f"includeInIndex = 0; path = MdirXTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};"
    )
    lines.append(
        f"\t\t{U['UITEST_PROD']} /* MdirXUITests.xctest */ "
        f"= {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; "
        f"includeInIndex = 0; path = MdirXUITests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};"
    )
    return "\n".join(lines)


def group_children_of(parent: Path | None) -> list[str]:
    """parent (None=root) 바로 아래의 자식 그룹/파일 UID 목록."""
    children: list[tuple[str, str]] = []  # (name, uid_line)
    # 하위 그룹
    for d in group_dirs_sorted:
        if d.parent == (parent if parent is not None else Path(".")):
            children.append((d.name, f"\t\t\t\t{group_uid(d)} /* {d.name} */,"))
    # 직접 자식 파일 (해당 디렉터리에 직접 있는 .swift)
    direct_files = [f for f in (app_files + unit_test_files + ui_test_files)
                    if f.parent == (parent if parent is not None else Path("."))]
    for f in direct_files:
        children.append((f.name, f"\t\t\t\t{fr_uid(f)} /* {f.name} */,"))
    # 정렬: 그룹 우선, 그 안에서 이름 알파벳
    children.sort(key=lambda x: x[0].lower())
    return [c[1] for c in children]


def main_group_children_lines() -> str:
    """루트 PBXGroup이 가질 자식들: 발견된 최상위 디렉터리 그룹 + Resources 그룹 + Products 그룹."""
    top_dirs: list[Path] = []
    for d in group_dirs_sorted:
        if len(d.parts) == 1:
            top_dirs.append(d)
    # 알파벳 정렬
    top_dirs.sort(key=lambda d: d.name.lower())

    lines: list[str] = []
    for d in top_dirs:
        lines.append(f"\t\t\t\t{group_uid(d)} /* {d.name} */,")
    # Tests/ 자체도 별도 그룹으로
    if any(d.parts[0] == "Tests" for d in group_dirs_sorted):
        # Tests는 그룹 내에 UnitTests/UITests 가짐
        pass  # 이미 top_dirs에 "Tests"가 포함될 것
    lines.append(f"\t\t\t\t{U['RES_GRP']} /* Resources */,")
    lines.append(f"\t\t\t\t{U['PROD_GRP']} /* Products */,")
    return "\n".join(lines)


def group_definition_lines() -> str:
    """각 디렉터리 그룹의 정의."""
    lines: list[str] = []
    for d in group_dirs_sorted:
        children = group_children_of(d)
        lines.append(f"\t\t{group_uid(d)} /* {d.name} */ = {{")
        lines.append("\t\t\tisa = PBXGroup;")
        lines.append("\t\t\tchildren = (")
        for c in children:
            lines.append(c)
        lines.append("\t\t\t);")
        lines.append(f"\t\t\tpath = {d.name};")
        lines.append("\t\t\tsourceTree = \"<group>\";")
        lines.append("\t\t};")
    return "\n".join(lines)


def app_sources_phase_lines() -> str:
    return "\n".join(
        f"\t\t\t\t{bf_uid(NS_BF_APP, f)} /* {f.name} in Sources */,"
        for f in app_files
    )


def test_sources_phase_lines() -> str:
    return "\n".join(
        f"\t\t\t\t{bf_uid(NS_BF_TEST, f)} /* {f.name} in Sources */,"
        for f in unit_test_files
    )


def uit_sources_phase_lines() -> str:
    return "\n".join(
        f"\t\t\t\t{bf_uid(NS_BF_UIT, f)} /* {f.name} in Sources */,"
        for f in ui_test_files
    )


# ─── 4) pbxproj 출력 ─────────────────────────────────────────────

u = U

pbx = f"""// !$*UTF8*$!
{{
\tarchiveVersion = 1;
\tclasses = {{
\t}};
\tobjectVersion = 56;
\tobjects = {{

/* Begin PBXBuildFile section */
{build_file_lines()}
/* End PBXBuildFile section */

/* Begin PBXContainerItemProxy section */
\t\t{u['PROXY']} /* PBXContainerItemProxy */ = {{
\t\t\tisa = PBXContainerItemProxy;
\t\t\tcontainerPortal = {u['PROJECT']} /* Project object */;
\t\t\tproxyType = 1;
\t\t\tremoteGlobalIDString = {u['MTARGET']};
\t\t\tremoteInfo = MdirX;
\t\t}};
\t\t{u['PROXYUT']} /* PBXContainerItemProxy */ = {{
\t\t\tisa = PBXContainerItemProxy;
\t\t\tcontainerPortal = {u['PROJECT']} /* Project object */;
\t\t\tproxyType = 1;
\t\t\tremoteGlobalIDString = {u['MTARGET']};
\t\t\tremoteInfo = MdirX;
\t\t}};
/* End PBXContainerItemProxy section */

/* Begin PBXFileReference section */
{file_reference_lines()}
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
\t\t{u['APFRMWK']} = {{isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; }};
\t\t{u['BAA']} = {{isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; }};
\t\t{u['BAUT']} = {{isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; }};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
\t\t{u['MAIN_GRP']} = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{main_group_children_lines()}
\t\t\t);
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{u['PROD_GRP']} /* Products */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{u['APP_PROD']} /* MdirX.app */,
\t\t\t\t{u['TEST_PROD']} /* MdirXTests.xctest */,
\t\t\t\t{u['UITEST_PROD']} /* MdirXUITests.xctest */,
\t\t\t);
\t\t\tname = Products;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{u['RES_GRP']} /* Resources */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{u['FR_ASSETS']} /* Assets.xcassets */,
\t\t\t\t{u['FR_EN']} /* en/Localizable.strings */,
\t\t\t\t{u['FR_KO']} /* ko/Localizable.strings */,
\t\t\t\t{u['FR_ENT']} /* MdirX.entitlements */,
\t\t\t);
\t\t\tname = Resources;
\t\t\tsourceTree = "<group>";
\t\t}};
{group_definition_lines()}
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
\t\t{u['MTARGET']} /* MdirX */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {u['ACFG']};
\t\t\tbuildPhases = (
\t\t\t\t{u['APSRC']},
\t\t\t\t{u['APRES']},
\t\t\t\t{u['APFRMWK']},
\t\t\t);
\t\t\tbuildRules = ();
\t\t\tdependencies = ();
\t\t\tname = MdirX;
\t\t\tproductName = MdirX;
\t\t\tproductReference = {u['APP_PROD']};
\t\t\tproductType = "com.apple.product-type.application";
\t\t}};
\t\t{u['TTARGET']} /* MdirXTests */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {u['TCFG']};
\t\t\tbuildPhases = (
\t\t\t\t{u['TPSRC']},
\t\t\t\t{u['BAA']},
\t\t\t);
\t\t\tbuildRules = ();
\t\t\tdependencies = (
\t\t\t\t{u['DEP']},
\t\t\t);
\t\t\tname = MdirXTests;
\t\t\tproductName = MdirXTests;
\t\t\tproductReference = {u['TEST_PROD']};
\t\t\tproductType = "com.apple.product-type.bundle.unit-test";
\t\t}};
\t\t{u['UTTARGET']} /* MdirXUITests */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {u['UTCFG']};
\t\t\tbuildPhases = (
\t\t\t\t{u['UTPSRC']},
\t\t\t\t{u['BAUT']},
\t\t\t);
\t\t\tbuildRules = ();
\t\t\tdependencies = (
\t\t\t\t{u['DEPUT']},
\t\t\t);
\t\t\tname = MdirXUITests;
\t\t\tproductName = MdirXUITests;
\t\t\tproductReference = {u['UITEST_PROD']};
\t\t\tproductType = "com.apple.product-type.bundle.ui-testing";
\t\t}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
\t\t{u['PROJECT']} /* Project object */ = {{
\t\t\tisa = PBXProject;
\t\t\tattributes = {{
\t\t\t\tLastSwiftUpdateCheck = 1500;
\t\t\t\tLastUpgradeCheck = 1500;
\t\t\t\tTargetAttributes = {{
\t\t\t\t\t{u['MTARGET']} = {{ CreatedOnToolsVersion = 15.0; }};
\t\t\t\t\t{u['TTARGET']} = {{ CreatedOnToolsVersion = 15.0; TestTargetID = {u['MTARGET']}; }};
\t\t\t\t\t{u['UTTARGET']} = {{ CreatedOnToolsVersion = 15.0; TestTargetID = {u['MTARGET']}; }};
\t\t\t\t}};
\t\t\t}};
\t\t\tbuildConfigurationList = {u['PCFG']};
\t\t\tcompatibilityVersion = "Xcode 14.0";
\t\t\tdevelopmentRegion = en;
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (en, ko, Base);
\t\t\tmainGroup = {u['MAIN_GRP']};
\t\t\tproductRefGroup = {u['PROD_GRP']};
\t\t\tprojectDirPath = "";
\t\t\tprojectRoot = "";
\t\t\ttargets = (
\t\t\t\t{u['MTARGET']},
\t\t\t\t{u['TTARGET']},
\t\t\t\t{u['UTTARGET']},
\t\t\t);
\t\t}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
\t\t{u['APRES']} = {{
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t\t{u['BF_ASSETS']} /* Assets.xcassets in Resources */,
\t\t\t\t{u['BF_EN']} /* en Localizable.strings in Resources */,
\t\t\t\t{u['BF_KO']} /* ko Localizable.strings in Resources */,
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
\t\t{u['APSRC']} = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
{app_sources_phase_lines()}
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
\t\t{u['TPSRC']} = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
{test_sources_phase_lines()}
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
\t\t{u['UTPSRC']} = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
{uit_sources_phase_lines()}
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXSourcesBuildPhase section */

/* Begin PBXTargetDependency section */
\t\t{u['DEP']} /* PBXTargetDependency */ = {{
\t\t\tisa = PBXTargetDependency;
\t\t\ttarget = {u['MTARGET']};
\t\t\ttargetProxy = {u['PROXY']};
\t\t}};
\t\t{u['DEPUT']} /* PBXTargetDependency */ = {{
\t\t\tisa = PBXTargetDependency;
\t\t\ttarget = {u['MTARGET']};
\t\t\ttargetProxy = {u['PROXYUT']};
\t\t}};
/* End PBXTargetDependency section */

/* Begin XCBuildConfiguration section */
\t\t{u['DBG_APP']} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tCODE_SIGN_ENTITLEMENTS = "MdirX/MdirX.entitlements";
\t\t\t\tCODE_SIGN_IDENTITY = "-";
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tDEVELOPMENT_TEAM = "";
\t\t\t\tENABLE_HARDENED_RUNTIME = YES;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tINFOPLIST_KEY_LSApplicationCategoryType = "public.app-category.utilities";
\t\t\t\tINFOPLIST_KEY_LSMinimumSystemVersion = 15.0;
\t\t\t\tINFOPLIST_KEY_NSHumanReadableCopyright = "";
\t\t\t\tMACOSX_DEPLOYMENT_TARGET = 15.0;
\t\t\t\tMARKETING_VERSION = 0.1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = app.mdirx.mac;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_STRICT_CONCURRENCY = complete;
\t\t\t\tSWIFT_VERSION = 6.0;
\t\t\t\tCONFIGURATION_BUILD_DIR = "$(SRCROOT)/dist";
\t\t\t\tCONFIGURATION_TEMP_DIR = "$(SRCROOT)/dist/Build/Intermediates.noindex";
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{u['REL_APP']} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tCODE_SIGN_ENTITLEMENTS = "MdirX/MdirX.entitlements";
\t\t\t\tCODE_SIGN_IDENTITY = "-";
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tDEVELOPMENT_TEAM = "";
\t\t\t\tENABLE_HARDENED_RUNTIME = YES;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tINFOPLIST_KEY_LSApplicationCategoryType = "public.app-category.utilities";
\t\t\t\tINFOPLIST_KEY_LSMinimumSystemVersion = 15.0;
\t\t\t\tINFOPLIST_KEY_NSHumanReadableCopyright = "";
\t\t\t\tARCHS = (arm64, x86_64);
\t\t\t\tMACOSX_DEPLOYMENT_TARGET = 15.0;
\t\t\t\tMARKETING_VERSION = 0.1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = app.mdirx.mac;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_STRICT_CONCURRENCY = complete;
\t\t\t\tSWIFT_VERSION = 6.0;
\t\t\t\tCONFIGURATION_BUILD_DIR = "$(SRCROOT)/dist";
\t\t\t\tCONFIGURATION_TEMP_DIR = "$(SRCROOT)/dist/Build/Intermediates.noindex";
\t\t\t}};
\t\t\tname = Release;
\t\t}};
\t\t{u['DBG_TEST']} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tBUNDLE_LOADER = "$(TEST_HOST)";
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tDEVELOPMENT_TEAM = "";
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tMACOSX_DEPLOYMENT_TARGET = 15.0;
\t\t\t\tMARKETING_VERSION = 0.1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = app.mdirx.mac.tests;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_STRICT_CONCURRENCY = complete;
\t\t\t\tSWIFT_VERSION = 6.0;
\t\t\t\tTEST_HOST = "$(BUILT_PRODUCTS_DIR)/MdirX.app/Contents/MacOS/MdirX";
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{u['REL_TEST']} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tBUNDLE_LOADER = "$(TEST_HOST)";
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tDEVELOPMENT_TEAM = "";
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tARCHS = (arm64, x86_64);
\t\t\t\tMACOSX_DEPLOYMENT_TARGET = 15.0;
\t\t\t\tMARKETING_VERSION = 0.1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = app.mdirx.mac.tests;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_STRICT_CONCURRENCY = complete;
\t\t\t\tSWIFT_VERSION = 6.0;
\t\t\t\tTEST_HOST = "$(BUILT_PRODUCTS_DIR)/MdirX.app/Contents/MacOS/MdirX";
\t\t\t}};
\t\t\tname = Release;
\t\t}};
\t\t{u['DBG_UIT']} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tDEVELOPMENT_TEAM = "";
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tMACOSX_DEPLOYMENT_TARGET = 15.0;
\t\t\t\tMARKETING_VERSION = 0.1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = app.mdirx.mac.uitests;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_STRICT_CONCURRENCY = complete;
\t\t\t\tSWIFT_VERSION = 6.0;
\t\t\t\tTEST_TARGET_NAME = MdirX;
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{u['REL_UIT']} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tDEVELOPMENT_TEAM = "";
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tARCHS = (arm64, x86_64);
\t\t\t\tMACOSX_DEPLOYMENT_TARGET = 15.0;
\t\t\t\tMARKETING_VERSION = 0.1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = app.mdirx.mac.uitests;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_STRICT_CONCURRENCY = complete;
\t\t\t\tSWIFT_VERSION = 6.0;
\t\t\t\tTEST_TARGET_NAME = MdirX;
\t\t\t}};
\t\t\tname = Release;
\t\t}};
\t\t{u['DBG_PROJ']} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;
\t\t\t\tENABLE_TESTABILITY = YES;
\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;
\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = ("DEBUG=1", "$(inherited)");
\t\t\t\tGCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
\t\t\t\tGCC_WARN_UNUSED_VARIABLE = YES;
\t\t\t\tLOCALIZATION_PREFERS_STRING_CATALOGS = YES;
\t\t\t\tMACOSX_DEPLOYMENT_TARGET = 15.0;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
\t\t\t\tONLY_ACTIVE_ARCH = YES;
\t\t\t\tSDKROOT = macosx;
\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{u['REL_PROJ']} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
\t\t\t\tENABLE_NS_ASSERTIONS = NO;
\t\t\t\tGCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
\t\t\t\tGCC_WARN_UNUSED_VARIABLE = YES;
\t\t\t\tLOCALIZATION_PREFERS_STRING_CATALOGS = YES;
\t\t\t\tMACOSX_DEPLOYMENT_TARGET = 15.0;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;
\t\t\t\tONLY_ACTIVE_ARCH = NO;
\t\t\t\tSDKROOT = macosx;
\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;
\t\t\t}};
\t\t\tname = Release;
\t\t}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
\t\t{u['ACFG']} = {{isa = XCConfigurationList; buildConfigurations = ({u['DBG_APP']}, {u['REL_APP']}); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }};
\t\t{u['TCFG']} = {{isa = XCConfigurationList; buildConfigurations = ({u['DBG_TEST']}, {u['REL_TEST']}); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }};
\t\t{u['UTCFG']} = {{isa = XCConfigurationList; buildConfigurations = ({u['DBG_UIT']}, {u['REL_UIT']}); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }};
\t\t{u['PCFG']} = {{isa = XCConfigurationList; buildConfigurations = ({u['DBG_PROJ']}, {u['REL_PROJ']}); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }};
/* End XCConfigurationList section */

\t}};
\trootObject = {u['PROJECT']} /* Project object */;
}}
"""


out = ROOT / "MdirX.xcodeproj" / "project.pbxproj"
out.write_text(pbx, encoding="utf-8")
print(
    f"Wrote {out}\n"
    f"  app src: {len(app_files)} files\n"
    f"  unit test: {len(unit_test_files)} files\n"
    f"  ui test: {len(ui_test_files)} files\n"
    f"  groups: {len(group_dirs_sorted)} directories"
)
