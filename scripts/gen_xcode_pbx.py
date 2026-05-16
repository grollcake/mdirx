#!/usr/bin/env python3
"""Generate MdirX.xcodeproj/project.pbxproj with all source files."""
import uuid
from pathlib import Path

def uid() -> str:
    return uuid.uuid4().hex[:24].upper()

U = {k: uid() for k in [
    "PROJECT", "MAIN_GRP", "PROD_GRP", "FEAT_GRP", "DUAL_GRP", "PANE_GRP",
    "CORE_PARENT", "CORE_PERSIST", "CORE_FS", "CORE_VOL", "DS_GRP",
    "APP_GRP", "RES_GRP", "TEST_GRP",
    "MDIRX_SUPP", "TPSRC", "UTPSRC",
    "APP_PROD", "TEST_PROD", "UITEST_PROD",
    # App sources
    "FR_APP", "FR_MODEL", "FR_ASSETS", "FR_ENT", "FR_EN", "FR_KO",
    "FR_ENTRY", "FR_FS", "FR_VOL",
    "FR_BROWSER", "FR_DUAL", "FR_PANE_ST",
    "FR_PANE_COL", "FR_FILE_LIST", "FR_SUMMARY", "FR_STATUS",
    "FR_BREADCRUMB", "FR_PANE_HEADER", "FR_PANE_ROW", "FR_VOL_BADGE",
    "FR_TOKENS",
    # Unit tests
    "FR_SMOKE", "FR_BROWSER_TEST", "FR_FSTEST", "FR_PSTEST",
    "FR_BREAD_TEST", "FR_DBLCLICK_TEST", "FR_CURSOR_TEST",
    "FR_PANE_ROWS_TEST", "FR_PARENT_SYNTH_TEST",
    "FR_ATTRS_TEST", "FR_TIME_TEST", "FR_STATUSBAR_TEST",
    # UI tests
    "FR_UI", "FR_UIT_DUAL", "FR_UIT_NAV",
    "FR_UIT_MOUSE", "FR_UIT_PARENT", "FR_UIT_NEXUS",
    # Build files - app
    "BF_APP", "BF_MODEL", "BF_ASSETS", "BF_EN", "BF_KO",
    "BF_ENTRY", "BF_FS", "BF_VOL",
    "BF_BROWSER", "BF_DUAL", "BF_PANE_ST",
    "BF_PANE_COL", "BF_FILE_LIST", "BF_SUMMARY", "BF_STATUS",
    "BF_BREADCRUMB", "BF_PANE_HEADER", "BF_PANE_ROW", "BF_VOL_BADGE",
    "BF_TOKENS",
    # Build files - unit tests
    "BF_SMOKE", "BF_BROWSER_TEST", "BF_FSTEST", "BF_PSTEST",
    "BF_BREAD_TEST", "BF_DBLCLICK_TEST", "BF_CURSOR_TEST",
    "BF_PANE_ROWS_TEST", "BF_PARENT_SYNTH_TEST",
    "BF_ATTRS_TEST", "BF_TIME_TEST", "BF_STATUSBAR_TEST",
    # Build files - UI tests
    "BF_UI", "BF_UIT_DUAL", "BF_UIT_NAV",
    "BF_UIT_MOUSE", "BF_UIT_PARENT", "BF_UIT_NEXUS",
    # Targets/phases
    "MTARGET", "TTARGET", "UTTARGET",
    "APSRC", "APRES", "APFRMWK", "BAA", "BAT", "BAB", "BAUT",
    "DEP", "DEPUT", "PROXY", "PROXYUT",
    "DBG_APP", "REL_APP", "DBG_TEST", "REL_TEST", "DBG_UIT", "REL_UIT",
    "DBG_PROJ", "REL_PROJ", "ACFG", "TCFG", "UTCFG", "PCFG",
]}

def sec(name):
    return f"/* Begin {name} section */"

def endsec(name):
    return f"/* End {name} section */"

u = U
pbx = f"""// !$*UTF8*$!
{{
\tarchiveVersion = 1;
\tclasses = {{
\t}};
\tobjectVersion = 56;
\tobjects = {{

{sec("PBXBuildFile")}
\t\t{u['BF_APP']} /* MdirXApp.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {u['FR_APP']}; }};
\t\t{u['BF_MODEL']} /* ModelContainer.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {u['FR_MODEL']}; }};
\t\t{u['BF_ENTRY']} /* DirectoryEntry.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {u['FR_ENTRY']}; }};
\t\t{u['BF_FS']} /* FileSystemActor.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {u['FR_FS']}; }};
\t\t{u['BF_VOL']} /* VolumeService.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {u['FR_VOL']}; }};
\t\t{u['BF_TOKENS']} /* Tokens.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {u['FR_TOKENS']}; }};
\t\t{u['BF_BROWSER']} /* BrowserSession.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {u['FR_BROWSER']}; }};
\t\t{u['BF_DUAL']} /* DualPaneView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {u['FR_DUAL']}; }};
\t\t{u['BF_PANE_ST']} /* PaneState.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {u['FR_PANE_ST']}; }};
\t\t{u['BF_PANE_COL']} /* PaneColumnView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {u['FR_PANE_COL']}; }};
\t\t{u['BF_FILE_LIST']} /* FileListView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {u['FR_FILE_LIST']}; }};
\t\t{u['BF_SUMMARY']} /* PaneSummaryView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {u['FR_SUMMARY']}; }};
\t\t{u['BF_STATUS']} /* PaneStatusBar.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {u['FR_STATUS']}; }};
\t\t{u['BF_BREADCRUMB']} /* BreadcrumbView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {u['FR_BREADCRUMB']}; }};
\t\t{u['BF_PANE_HEADER']} /* PaneHeaderView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {u['FR_PANE_HEADER']}; }};
\t\t{u['BF_PANE_ROW']} /* PaneRow.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {u['FR_PANE_ROW']}; }};
\t\t{u['BF_VOL_BADGE']} /* VolumeBadgeView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {u['FR_VOL_BADGE']}; }};
\t\t{u['BF_ASSETS']} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {u['FR_ASSETS']}; }};
\t\t{u['BF_EN']} /* en Localizable.strings in Resources */ = {{isa = PBXBuildFile; fileRef = {u['FR_EN']}; }};
\t\t{u['BF_KO']} /* ko Localizable.strings in Resources */ = {{isa = PBXBuildFile; fileRef = {u['FR_KO']}; }};
\t\t{u['BF_SMOKE']} /* SmokeTests.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {u['FR_SMOKE']}; }};
\t\t{u['BF_BROWSER_TEST']} /* BrowserSessionTests.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {u['FR_BROWSER_TEST']}; }};
\t\t{u['BF_FSTEST']} /* FileSystemActorTests.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {u['FR_FSTEST']}; }};
\t\t{u['BF_PSTEST']} /* PaneStateTests.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {u['FR_PSTEST']}; }};
\t\t{u['BF_BREAD_TEST']} /* BreadcrumbBreakdownTests.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {u['FR_BREAD_TEST']}; }};
\t\t{u['BF_DBLCLICK_TEST']} /* DoubleClickRoutingTests.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {u['FR_DBLCLICK_TEST']}; }};
\t\t{u['BF_CURSOR_TEST']} /* PaneCursorInitTests.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {u['FR_CURSOR_TEST']}; }};
\t\t{u['BF_PANE_ROWS_TEST']} /* PaneRowsTests.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {u['FR_PANE_ROWS_TEST']}; }};
\t\t{u['BF_PARENT_SYNTH_TEST']} /* ParentLinkSynthesisTests.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {u['FR_PARENT_SYNTH_TEST']}; }};
\t\t{u['BF_ATTRS_TEST']} /* AttrsFourCharacterTests.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {u['FR_ATTRS_TEST']}; }};
\t\t{u['BF_TIME_TEST']} /* TimeHHmmFormatTests.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {u['FR_TIME_TEST']}; }};
\t\t{u['BF_STATUSBAR_TEST']} /* StatusBarFormatTests.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {u['FR_STATUSBAR_TEST']}; }};
\t\t{u['BF_UI']} /* LaunchTests.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {u['FR_UI']}; }};
\t\t{u['BF_UIT_DUAL']} /* DualPaneTabToggleTests.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {u['FR_UIT_DUAL']}; }};
\t\t{u['BF_UIT_NAV']} /* FileListNavigationTests.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {u['FR_UIT_NAV']}; }};
\t\t{u['BF_UIT_MOUSE']} /* MouseActivationAndDoubleClickTests.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {u['FR_UIT_MOUSE']}; }};
\t\t{u['BF_UIT_PARENT']} /* ParentLinkVisibleTests.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {u['FR_UIT_PARENT']}; }};
\t\t{u['BF_UIT_NEXUS']} /* NexusLookExactTests.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {u['FR_UIT_NEXUS']}; }};
{endsec("PBXBuildFile")}

{sec("PBXFileReference")}
\t\t{u['APP_PROD']} /* MdirX.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = MdirX.app; sourceTree = BUILT_PRODUCTS_DIR; }};
\t\t{u['TEST_PROD']} /* MdirXTests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = MdirXTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};
\t\t{u['UITEST_PROD']} /* MdirXUITests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = MdirXUITests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};
\t\t{u['FR_APP']} /* MdirXApp.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = MdirXApp.swift; sourceTree = "<group>"; }};
\t\t{u['FR_MODEL']} /* ModelContainer.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ModelContainer.swift; sourceTree = "<group>"; }};
\t\t{u['FR_ENTRY']} /* DirectoryEntry.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = DirectoryEntry.swift; sourceTree = "<group>"; }};
\t\t{u['FR_FS']} /* FileSystemActor.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = FileSystemActor.swift; sourceTree = "<group>"; }};
\t\t{u['FR_VOL']} /* VolumeService.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = VolumeService.swift; sourceTree = "<group>"; }};
\t\t{u['FR_TOKENS']} /* Tokens.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = Tokens.swift; sourceTree = "<group>"; }};
\t\t{u['FR_BROWSER']} /* BrowserSession.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = BrowserSession.swift; sourceTree = "<group>"; }};
\t\t{u['FR_DUAL']} /* DualPaneView.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = DualPaneView.swift; sourceTree = "<group>"; }};
\t\t{u['FR_PANE_ST']} /* PaneState.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = PaneState.swift; sourceTree = "<group>"; }};
\t\t{u['FR_PANE_COL']} /* PaneColumnView.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = PaneColumnView.swift; sourceTree = "<group>"; }};
\t\t{u['FR_FILE_LIST']} /* FileListView.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = FileListView.swift; sourceTree = "<group>"; }};
\t\t{u['FR_SUMMARY']} /* PaneSummaryView.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = PaneSummaryView.swift; sourceTree = "<group>"; }};
\t\t{u['FR_STATUS']} /* PaneStatusBar.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = PaneStatusBar.swift; sourceTree = "<group>"; }};
\t\t{u['FR_BREADCRUMB']} /* BreadcrumbView.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = BreadcrumbView.swift; sourceTree = "<group>"; }};
\t\t{u['FR_PANE_HEADER']} /* PaneHeaderView.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = PaneHeaderView.swift; sourceTree = "<group>"; }};
\t\t{u['FR_PANE_ROW']} /* PaneRow.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = PaneRow.swift; sourceTree = "<group>"; }};
\t\t{u['FR_VOL_BADGE']} /* VolumeBadgeView.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = VolumeBadgeView.swift; sourceTree = "<group>"; }};
\t\t{u['FR_SMOKE']} /* SmokeTests.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = SmokeTests.swift; sourceTree = "<group>"; }};
\t\t{u['FR_BROWSER_TEST']} /* BrowserSessionTests.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = BrowserSessionTests.swift; sourceTree = "<group>"; }};
\t\t{u['FR_FSTEST']} /* FileSystemActorTests.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = FileSystemActorTests.swift; sourceTree = "<group>"; }};
\t\t{u['FR_PSTEST']} /* PaneStateTests.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = PaneStateTests.swift; sourceTree = "<group>"; }};
\t\t{u['FR_BREAD_TEST']} /* BreadcrumbBreakdownTests.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = BreadcrumbBreakdownTests.swift; sourceTree = "<group>"; }};
\t\t{u['FR_DBLCLICK_TEST']} /* DoubleClickRoutingTests.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = DoubleClickRoutingTests.swift; sourceTree = "<group>"; }};
\t\t{u['FR_CURSOR_TEST']} /* PaneCursorInitTests.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = PaneCursorInitTests.swift; sourceTree = "<group>"; }};
\t\t{u['FR_PANE_ROWS_TEST']} /* PaneRowsTests.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = PaneRowsTests.swift; sourceTree = "<group>"; }};
\t\t{u['FR_PARENT_SYNTH_TEST']} /* ParentLinkSynthesisTests.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ParentLinkSynthesisTests.swift; sourceTree = "<group>"; }};
\t\t{u['FR_ATTRS_TEST']} /* AttrsFourCharacterTests.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = AttrsFourCharacterTests.swift; sourceTree = "<group>"; }};
\t\t{u['FR_TIME_TEST']} /* TimeHHmmFormatTests.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = TimeHHmmFormatTests.swift; sourceTree = "<group>"; }};
\t\t{u['FR_STATUSBAR_TEST']} /* StatusBarFormatTests.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = StatusBarFormatTests.swift; sourceTree = "<group>"; }};
\t\t{u['FR_UI']} /* LaunchTests.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = LaunchTests.swift; sourceTree = "<group>"; }};
\t\t{u['FR_UIT_DUAL']} /* DualPaneTabToggleTests.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = DualPaneTabToggleTests.swift; sourceTree = "<group>"; }};
\t\t{u['FR_UIT_NAV']} /* FileListNavigationTests.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = FileListNavigationTests.swift; sourceTree = "<group>"; }};
\t\t{u['FR_UIT_MOUSE']} /* MouseActivationAndDoubleClickTests.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = MouseActivationAndDoubleClickTests.swift; sourceTree = "<group>"; }};
\t\t{u['FR_UIT_PARENT']} /* ParentLinkVisibleTests.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ParentLinkVisibleTests.swift; sourceTree = "<group>"; }};
\t\t{u['FR_UIT_NEXUS']} /* NexusLookExactTests.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = NexusLookExactTests.swift; sourceTree = "<group>"; }};
\t\t{u['FR_ASSETS']} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>"; }};
\t\t{u['FR_ENT']} /* MdirX.entitlements */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; path = MdirX.entitlements; sourceTree = "<group>"; }};
\t\t{u['FR_EN']} /* en/Localizable.strings */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.strings; name = Localizable.strings; path = Localization/en.lproj/Localizable.strings; sourceTree = "<group>"; }};
\t\t{u['FR_KO']} /* ko/Localizable.strings */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.strings; name = Localizable.strings; path = Localization/ko.lproj/Localizable.strings; sourceTree = "<group>"; }};
{endsec("PBXFileReference")}

{sec("PBXFrameworksBuildPhase")}
\t\t{u['APFRMWK']} = {{isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; }};
\t\t{u['BAT']} = {{isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; }};
\t\t{u['BAUT']} = {{isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; }};
{endsec("PBXFrameworksBuildPhase")}

{sec("PBXGroup")}
\t\t{u['MAIN_GRP']} = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{u['APP_GRP']} /* App */,
\t\t\t\t{u['FEAT_GRP']} /* Features */,
\t\t\t\t{u['CORE_PARENT']} /* Core */,
\t\t\t\t{u['DS_GRP']} /* DesignSystem */,
\t\t\t\t{u['RES_GRP']} /* Resources */,
\t\t\t\t{u['TEST_GRP']} /* Tests */,
\t\t\t\t{u['MDIRX_SUPP']} /* MdirX */,
\t\t\t\t{u['PROD_GRP']} /* Products */,
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
\t\t{u['APP_GRP']} /* App */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = ({u['FR_APP']});
\t\t\tpath = App;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{u['DS_GRP']} /* DesignSystem */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = ({u['FR_TOKENS']});
\t\t\tpath = DesignSystem;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{u['FEAT_GRP']} /* Features */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{u['DUAL_GRP']} /* DualPane */,
\t\t\t\t{u['PANE_GRP']} /* Pane */,
\t\t\t);
\t\t\tpath = Features;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{u['DUAL_GRP']} /* DualPane */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{u['FR_BROWSER']},
\t\t\t\t{u['FR_PANE_ST']},
\t\t\t\t{u['FR_DUAL']},
\t\t\t);
\t\t\tpath = DualPane;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{u['PANE_GRP']} /* Pane */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{u['FR_BREADCRUMB']},
\t\t\t\t{u['FR_FILE_LIST']},
\t\t\t\t{u['FR_PANE_COL']},
\t\t\t\t{u['FR_PANE_HEADER']},
\t\t\t\t{u['FR_PANE_ROW']},
\t\t\t\t{u['FR_STATUS']},
\t\t\t\t{u['FR_SUMMARY']},
\t\t\t\t{u['FR_VOL_BADGE']},
\t\t\t);
\t\t\tpath = Pane;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{u['CORE_PARENT']} /* Core */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{u['CORE_PERSIST']},
\t\t\t\t{u['CORE_FS']},
\t\t\t\t{u['CORE_VOL']},
\t\t\t);
\t\t\tpath = Core;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{u['CORE_PERSIST']} /* Persistence */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = ({u['FR_MODEL']});
\t\t\tpath = Persistence;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{u['CORE_FS']} /* FileSystem */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{u['FR_ENTRY']},
\t\t\t\t{u['FR_FS']},
\t\t\t);
\t\t\tpath = FileSystem;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{u['CORE_VOL']} /* Volumes */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = ({u['FR_VOL']});
\t\t\tpath = Volumes;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{u['RES_GRP']} /* Resources */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{u['FR_ASSETS']},
\t\t\t\t{u['FR_EN']},
\t\t\t\t{u['FR_KO']},
\t\t\t);
\t\t\tpath = Resources;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{u['TEST_GRP']} /* Tests */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{u['TPSRC']} /* UnitTests */,
\t\t\t\t{u['UTPSRC']} /* UITests */,
\t\t\t);
\t\t\tpath = Tests;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{u['TPSRC']} /* UnitTests */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{u['FR_SMOKE']},
\t\t\t\t{u['FR_BROWSER_TEST']},
\t\t\t\t{u['FR_FSTEST']},
\t\t\t\t{u['FR_PSTEST']},
\t\t\t\t{u['FR_BREAD_TEST']},
\t\t\t\t{u['FR_DBLCLICK_TEST']},
\t\t\t\t{u['FR_CURSOR_TEST']},
\t\t\t\t{u['FR_PANE_ROWS_TEST']},
\t\t\t\t{u['FR_PARENT_SYNTH_TEST']},
\t\t\t\t{u['FR_ATTRS_TEST']},
\t\t\t\t{u['FR_TIME_TEST']},
\t\t\t\t{u['FR_STATUSBAR_TEST']},
\t\t\t);
\t\t\tpath = UnitTests;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{u['UTPSRC']} /* UITests */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{u['FR_UI']},
\t\t\t\t{u['FR_UIT_DUAL']},
\t\t\t\t{u['FR_UIT_NAV']},
\t\t\t\t{u['FR_UIT_MOUSE']},
\t\t\t\t{u['FR_UIT_PARENT']},
\t\t\t\t{u['FR_UIT_NEXUS']},
\t\t\t);
\t\t\tpath = UITests;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{u['MDIRX_SUPP']} /* MdirX */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = ({u['FR_ENT']});
\t\t\tpath = MdirX;
\t\t\tsourceTree = "<group>";
\t\t}};
{endsec("PBXGroup")}

{sec("PBXNativeTarget")}
\t\t{u['MTARGET']} /* MdirX */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {u['ACFG']};
\t\t\tbuildPhases = ({u['APSRC']}, {u['APFRMWK']}, {u['APRES']});
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
\t\t\tbuildPhases = ({u['BAA']}, {u['BAT']});
\t\t\tbuildRules = ();
\t\t\tdependencies = ({u['DEP']});
\t\t\tname = MdirXTests;
\t\t\tproductName = MdirXTests;
\t\t\tproductReference = {u['TEST_PROD']};
\t\t\tproductType = "com.apple.product-type.bundle.unit-test";
\t\t}};
\t\t{u['UTTARGET']} /* MdirXUITests */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {u['UTCFG']};
\t\t\tbuildPhases = ({u['BAB']}, {u['BAUT']});
\t\t\tbuildRules = ();
\t\t\tdependencies = ({u['DEPUT']});
\t\t\tname = MdirXUITests;
\t\t\tproductName = MdirXUITests;
\t\t\tproductReference = {u['UITEST_PROD']};
\t\t\tproductType = "com.apple.product-type.bundle.ui-testing";
\t\t}};
{endsec("PBXNativeTarget")}

{sec("PBXProject")}
\t\t{u['PROJECT']} /* Project object */ = {{
\t\t\tisa = PBXProject;
\t\t\tattributes = {{
\t\t\t\tBuildIndependentTargetsInParallel = 1;
\t\t\t\tLastSwiftUpdateCheck = 1600;
\t\t\t\tLastUpgradeCheck = 1600;
\t\t\t\tTargetAttributes = {{
\t\t\t\t\t{u['MTARGET']} = {{ CreatedOnToolsVersion = 16.0; }};
\t\t\t\t\t{u['TTARGET']} = {{ CreatedOnToolsVersion = 16.0; TestTargetID = {u['MTARGET']}; }};
\t\t\t\t\t{u['UTTARGET']} = {{ CreatedOnToolsVersion = 16.0; TestTargetID = {u['MTARGET']}; }};
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
\t\t\ttargets = ({u['MTARGET']}, {u['TTARGET']}, {u['UTTARGET']});
\t\t}};
{endsec("PBXProject")}

{sec("PBXResourcesBuildPhase")}
\t\t{u['APRES']} = {{
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t\t{u['BF_ASSETS']},
\t\t\t\t{u['BF_EN']},
\t\t\t\t{u['BF_KO']},
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
{endsec("PBXResourcesBuildPhase")}

{sec("PBXSourcesBuildPhase")}
\t\t{u['APSRC']} /* App Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t\t{u['BF_APP']},
\t\t\t\t{u['BF_MODEL']},
\t\t\t\t{u['BF_ENTRY']},
\t\t\t\t{u['BF_FS']},
\t\t\t\t{u['BF_VOL']},
\t\t\t\t{u['BF_TOKENS']},
\t\t\t\t{u['BF_BROWSER']},
\t\t\t\t{u['BF_PANE_ST']},
\t\t\t\t{u['BF_DUAL']},
\t\t\t\t{u['BF_BREADCRUMB']},
\t\t\t\t{u['BF_FILE_LIST']},
\t\t\t\t{u['BF_PANE_COL']},
\t\t\t\t{u['BF_PANE_HEADER']},
\t\t\t\t{u['BF_PANE_ROW']},
\t\t\t\t{u['BF_STATUS']},
\t\t\t\t{u['BF_SUMMARY']},
\t\t\t\t{u['BF_VOL_BADGE']},
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
\t\t{u['BAA']} /* Unit Test Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t\t{u['BF_SMOKE']},
\t\t\t\t{u['BF_BROWSER_TEST']},
\t\t\t\t{u['BF_FSTEST']},
\t\t\t\t{u['BF_PSTEST']},
\t\t\t\t{u['BF_BREAD_TEST']},
\t\t\t\t{u['BF_DBLCLICK_TEST']},
\t\t\t\t{u['BF_CURSOR_TEST']},
\t\t\t\t{u['BF_PANE_ROWS_TEST']},
\t\t\t\t{u['BF_PARENT_SYNTH_TEST']},
\t\t\t\t{u['BF_ATTRS_TEST']},
\t\t\t\t{u['BF_TIME_TEST']},
\t\t\t\t{u['BF_STATUSBAR_TEST']},
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
\t\t{u['BAB']} /* UI Test Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t\t{u['BF_UI']},
\t\t\t\t{u['BF_UIT_DUAL']},
\t\t\t\t{u['BF_UIT_NAV']},
\t\t\t\t{u['BF_UIT_MOUSE']},
\t\t\t\t{u['BF_UIT_PARENT']},
\t\t\t\t{u['BF_UIT_NEXUS']},
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
{endsec("PBXSourcesBuildPhase")}

{sec("PBXTargetDependency")}
\t\t{u['DEP']} = {{isa = PBXTargetDependency; target = {u['MTARGET']}; targetProxy = {u['PROXY']}; }};
\t\t{u['DEPUT']} = {{isa = PBXTargetDependency; target = {u['MTARGET']}; targetProxy = {u['PROXYUT']}; }};
{endsec("PBXTargetDependency")}

{sec("PBXContainerItemProxy")}
\t\t{u['PROXY']} = {{isa = PBXContainerItemProxy; containerPortal = {u['PROJECT']}; proxyType = 1; remoteGlobalIDString = {u['MTARGET']}; remoteInfo = MdirX; }};
\t\t{u['PROXYUT']} = {{isa = PBXContainerItemProxy; containerPortal = {u['PROJECT']}; proxyType = 1; remoteGlobalIDString = {u['MTARGET']}; remoteInfo = MdirX; }};
{endsec("PBXContainerItemProxy")}

{sec("XCBuildConfiguration")}
\t\t{u['DBG_APP']} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tCODE_SIGN_ENTITLEMENTS = MdirX/MdirX.entitlements;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCOMBINE_HIDPI_IMAGES = YES;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tDEAD_CODE_STRIPPING = YES;
\t\t\t\tDEVELOPMENT_TEAM = "";
\t\t\t\tENABLE_HARDENED_RUNTIME = YES;
\t\t\t\tENABLE_PREVIEWS = NO;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tINFOPLIST_KEY_CFBundleDisplayName = MdirX;
\t\t\t\tINFOPLIST_KEY_LSApplicationCategoryType = "public.app-category.utilities";
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = ("$(inherited)", "@executable_path/../Frameworks");
\t\t\t\tMACOSX_DEPLOYMENT_TARGET = 15.0;
\t\t\t\tMARKETING_VERSION = 0.1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = app.mdirx.mac;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_STRICT_CONCURRENCY = complete;
\t\t\t\tSWIFT_VERSION = 6.0;
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{u['REL_APP']} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tCODE_SIGN_ENTITLEMENTS = MdirX/MdirX.entitlements;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCOMBINE_HIDPI_IMAGES = YES;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tDEAD_CODE_STRIPPING = YES;
\t\t\t\tDEVELOPMENT_TEAM = "";
\t\t\t\tENABLE_HARDENED_RUNTIME = YES;
\t\t\t\tENABLE_PREVIEWS = NO;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tINFOPLIST_KEY_CFBundleDisplayName = MdirX;
\t\t\t\tINFOPLIST_KEY_LSApplicationCategoryType = "public.app-category.utilities";
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = ("$(inherited)", "@executable_path/../Frameworks");
\t\t\t\tARCHS = (arm64, x86_64);
\t\t\t\tMACOSX_DEPLOYMENT_TARGET = 15.0;
\t\t\t\tMARKETING_VERSION = 0.1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = app.mdirx.mac;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_STRICT_CONCURRENCY = complete;
\t\t\t\tSWIFT_VERSION = 6.0;
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
\t\t\t\tTEST_HOST = "$(BUILT_PRODUCTS_DIR)/MdirX.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/MdirX";
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
\t\t\t\tTEST_HOST = "$(BUILT_PRODUCTS_DIR)/MdirX.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/MdirX";
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
{endsec("XCBuildConfiguration")}

{sec("XCConfigurationList")}
\t\t{u['ACFG']} = {{isa = XCConfigurationList; buildConfigurations = ({u['DBG_APP']}, {u['REL_APP']}); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }};
\t\t{u['TCFG']} = {{isa = XCConfigurationList; buildConfigurations = ({u['DBG_TEST']}, {u['REL_TEST']}); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }};
\t\t{u['UTCFG']} = {{isa = XCConfigurationList; buildConfigurations = ({u['DBG_UIT']}, {u['REL_UIT']}); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }};
\t\t{u['PCFG']} = {{isa = XCConfigurationList; buildConfigurations = ({u['DBG_PROJ']}, {u['REL_PROJ']}); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }};
{endsec("XCConfigurationList")}

\t}};
\trootObject = {u['PROJECT']} /* Project object */;
}}
"""

root = Path(__file__).resolve().parents[1]
out = root / "MdirX.xcodeproj" / "project.pbxproj"
out.write_text(pbx, encoding="utf-8")
print(f"Wrote {out}")
