#!/usr/bin/env python3
"""Generate MdirX.xcodeproj/project.pbxproj (one-off scaffold)."""
import uuid
from pathlib import Path

def uid() -> str:
    return uuid.uuid4().hex[:24].upper()

U = {k: uid() for k in [
    "PROJECT", "MAIN_GRP", "PROD_GRP", "APP_GRP", "CORE_GRP", "RES_GRP", "TEST_GRP",
    "MDIRX_SUPP", "TPSRC", "UTPSRC",
    "APP_PROD", "TEST_PROD", "UITEST_PROD",
    "FR_APP", "FR_CV", "FR_MODEL", "FR_ASSETS", "FR_ENT", "FR_EN", "FR_KO", "FR_SMOKE", "FR_UI",
    "BF_APP", "BF_CV", "BF_MODEL", "BF_ASSETS", "BF_EN", "BF_KO", "BF_SMOKE", "BF_UI",
    "MTARGET", "TTARGET", "UTTARGET",
    "APSRC", "APRES", "APFRMWK", "BAA", "BAT", "BAB", "BAUT",
    "DEP", "DEPUT", "PROXY", "PROXYUT",
    "DBG_APP", "REL_APP", "DBG_TEST", "REL_TEST", "DBG_UIT", "REL_UIT",
    "DBG_PROJ", "REL_PROJ", "ACFG", "TCFG", "UTCFG", "PCFG",
]}

def sec(name: str) -> str:
    return f"/* Begin {name} section */"

def endsec(name: str) -> str:
    return f"/* End {name} section */"

u = U  # shorthand
pbx = f"""// !$*UTF8*$!
{{
	archiveVersion = 1;
	classes = {{
	}};
	objectVersion = 56;
	objects = {{

{sec("PBXBuildFile")}
		{u['BF_APP']} /* MdirXApp.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {u['FR_APP']} /* MdirXApp.swift */; }};
		{u['BF_CV']} /* ContentView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {u['FR_CV']} /* ContentView.swift */; }};
		{u['BF_MODEL']} /* ModelContainer.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {u['FR_MODEL']} /* ModelContainer.swift */; }};
		{u['BF_ASSETS']} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {u['FR_ASSETS']} /* Assets.xcassets */; }};
		{u['BF_EN']} /* Localizable.strings in Resources */ = {{isa = PBXBuildFile; fileRef = {u['FR_EN']} /* Localizable.strings */; }};
		{u['BF_KO']} /* Localizable.strings in Resources */ = {{isa = PBXBuildFile; fileRef = {u['FR_KO']} /* Localizable.strings */; }};
		{u['BF_SMOKE']} /* SmokeTests.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {u['FR_SMOKE']} /* SmokeTests.swift */; }};
		{u['BF_UI']} /* LaunchTests.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {u['FR_UI']} /* LaunchTests.swift */; }};
{endsec("PBXBuildFile")}

{sec("PBXFileReference")}
		{u['APP_PROD']} /* MdirX.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = MdirX.app; sourceTree = BUILT_PRODUCTS_DIR; }};
		{u['TEST_PROD']} /* MdirXTests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = MdirXTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};
		{u['UITEST_PROD']} /* MdirXUITests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = MdirXUITests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};
		{u['FR_APP']} /* MdirXApp.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = MdirXApp.swift; sourceTree = "<group>"; }};
		{u['FR_CV']} /* ContentView.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ContentView.swift; sourceTree = "<group>"; }};
		{u['FR_MODEL']} /* ModelContainer.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ModelContainer.swift; sourceTree = "<group>"; }};
		{u['FR_ASSETS']} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>"; }};
		{u['FR_ENT']} /* MdirX.entitlements */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; path = MdirX.entitlements; sourceTree = "<group>"; }};
		{u['FR_EN']} /* Localizable.strings */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.strings; name = Localizable.strings; path = Localization/en.lproj/Localizable.strings; sourceTree = "<group>"; }};
		{u['FR_KO']} /* Localizable.strings */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.strings; name = Localizable.strings; path = Localization/ko.lproj/Localizable.strings; sourceTree = "<group>"; }};
		{u['FR_SMOKE']} /* SmokeTests.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = SmokeTests.swift; sourceTree = "<group>"; }};
		{u['FR_UI']} /* LaunchTests.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = LaunchTests.swift; sourceTree = "<group>"; }};
{endsec("PBXFileReference")}

{sec("PBXFrameworksBuildPhase")}
		{u['APFRMWK']} /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
		{u['BAT']} /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
		{u['BAUT']} /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
{endsec("PBXFrameworksBuildPhase")}

{sec("PBXGroup")}
		{u['MAIN_GRP']} = {{
			isa = PBXGroup;
			children = (
				{u['APP_GRP']} /* App */,
				{u['CORE_GRP']} /* Core */,
				{u['RES_GRP']} /* Resources */,
				{u['TEST_GRP']} /* Tests */,
				{u['MDIRX_SUPP']} /* MdirX */,
				{u['PROD_GRP']} /* Products */,
			);
			sourceTree = "<group>";
		}};
		{u['PROD_GRP']} /* Products */ = {{
			isa = PBXGroup;
			children = (
				{u['APP_PROD']} /* MdirX.app */,
				{u['TEST_PROD']} /* MdirXTests.xctest */,
				{u['UITEST_PROD']} /* MdirXUITests.xctest */,
			);
			name = Products;
			sourceTree = "<group>";
		}};
		{u['APP_GRP']} /* App */ = {{
			isa = PBXGroup;
			children = (
				{u['FR_APP']} /* MdirXApp.swift */,
				{u['FR_CV']} /* ContentView.swift */,
			);
			path = App;
			sourceTree = "<group>";
		}};
		{u['CORE_GRP']} /* Core */ = {{
			isa = PBXGroup;
			children = (
				{u['FR_MODEL']} /* ModelContainer.swift */,
			);
			path = Core/Persistence;
			sourceTree = "<group>";
		}};
		{u['RES_GRP']} /* Resources */ = {{
			isa = PBXGroup;
			children = (
				{u['FR_ASSETS']} /* Assets.xcassets */,
				{u['FR_EN']} /* Localizable.strings */,
				{u['FR_KO']} /* Localizable.strings */,
			);
			path = Resources;
			sourceTree = "<group>";
		}};
		{u['TEST_GRP']} /* Tests */ = {{
			isa = PBXGroup;
			children = (
				{u['TPSRC']} /* UnitTests */,
				{u['UTPSRC']} /* UITests */,
			);
			path = Tests;
			sourceTree = "<group>";
		}};
		{u['TPSRC']} /* UnitTests */ = {{
			isa = PBXGroup;
			children = (
				{u['FR_SMOKE']} /* SmokeTests.swift */,
			);
			path = UnitTests;
			sourceTree = "<group>";
		}};
		{u['UTPSRC']} /* UITests */ = {{
			isa = PBXGroup;
			children = (
				{u['FR_UI']} /* LaunchTests.swift */,
			);
			path = UITests;
			sourceTree = "<group>";
		}};
		{u['MDIRX_SUPP']} /* MdirX */ = {{
			isa = PBXGroup;
			children = (
				{u['FR_ENT']} /* MdirX.entitlements */,
			);
			path = MdirX;
			sourceTree = "<group>";
		}};
{endsec("PBXGroup")}

{sec("PBXNativeTarget")}
		{u['MTARGET']} /* MdirX */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {u['ACFG']} /* Build configuration list for PBXNativeTarget "MdirX" */;
			buildPhases = (
				{u['APSRC']} /* Sources */,
				{u['APFRMWK']} /* Frameworks */,
				{u['APRES']} /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = MdirX;
			productName = MdirX;
			productReference = {u['APP_PROD']} /* MdirX.app */;
			productType = "com.apple.product-type.application";
		}};
		{u['TTARGET']} /* MdirXTests */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {u['TCFG']} /* Build configuration list for PBXNativeTarget "MdirXTests" */;
			buildPhases = (
				{u['BAA']} /* Sources */,
				{u['BAT']} /* Frameworks */,
			);
			buildRules = (
			);
			dependencies = (
				{u['DEP']} /* PBXTargetDependency */,
			);
			name = MdirXTests;
			productName = MdirXTests;
			productReference = {u['TEST_PROD']} /* MdirXTests.xctest */;
			productType = "com.apple.product-type.bundle.unit-test";
		}};
		{u['UTTARGET']} /* MdirXUITests */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {u['UTCFG']} /* Build configuration list for PBXNativeTarget "MdirXUITests" */;
			buildPhases = (
				{u['BAB']} /* Sources */,
				{u['BAUT']} /* Frameworks */,
			);
			buildRules = (
			);
			dependencies = (
				{u['DEPUT']} /* PBXTargetDependency */,
			);
			name = MdirXUITests;
			productName = MdirXUITests;
			productReference = {u['UITEST_PROD']} /* MdirXUITests.xctest */;
			productType = "com.apple.product-type.bundle.ui-testing";
		}};
{endsec("PBXNativeTarget")}

{sec("PBXProject")}
		{u['PROJECT']} /* Project object */ = {{
			isa = PBXProject;
			attributes = {{
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1600;
				LastUpgradeCheck = 1600;
				TargetAttributes = {{
					{u['MTARGET']} = {{
						CreatedOnToolsVersion = 16.0;
					}};
					{u['TTARGET']} = {{
						CreatedOnToolsVersion = 16.0;
						TestTargetID = {u['MTARGET']};
					}};
					{u['UTTARGET']} = {{
						CreatedOnToolsVersion = 16.0;
						TestTargetID = {u['MTARGET']};
					}};
				}};
			}};
			buildConfigurationList = {u['PCFG']} /* Build configuration list for PBXProject "MdirX" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				ko,
				Base,
			);
			mainGroup = {u['MAIN_GRP']};
			productRefGroup = {u['PROD_GRP']} /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				{u['MTARGET']} /* MdirX */,
				{u['TTARGET']} /* MdirXTests */,
				{u['UTTARGET']} /* MdirXUITests */,
			);
		}};
{endsec("PBXProject")}

{sec("PBXResourcesBuildPhase")}
		{u['APRES']} /* Resources */ = {{
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				{u['BF_ASSETS']} /* Assets.xcassets in Resources */,
				{u['BF_EN']} /* Localizable.strings in Resources */,
				{u['BF_KO']} /* Localizable.strings in Resources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
{endsec("PBXResourcesBuildPhase")}

{sec("PBXSourcesBuildPhase")}
		{u['APSRC']} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				{u['BF_APP']} /* MdirXApp.swift in Sources */,
				{u['BF_CV']} /* ContentView.swift in Sources */,
				{u['BF_MODEL']} /* ModelContainer.swift in Sources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
		{u['BAA']} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				{u['BF_SMOKE']} /* SmokeTests.swift in Sources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
		{u['BAB']} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				{u['BF_UI']} /* LaunchTests.swift in Sources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
{endsec("PBXSourcesBuildPhase")}

{sec("PBXTargetDependency")}
		{u['DEP']} /* PBXTargetDependency */ = {{
			isa = PBXTargetDependency;
			target = {u['MTARGET']} /* MdirX */;
			targetProxy = {u['PROXY']} /* PBXContainerItemProxy */;
		}};
		{u['DEPUT']} /* PBXTargetDependency */ = {{
			isa = PBXTargetDependency;
			target = {u['MTARGET']} /* MdirX */;
			targetProxy = {u['PROXYUT']} /* PBXContainerItemProxy */;
		}};
{endsec("PBXTargetDependency")}

{sec("PBXContainerItemProxy")}
		{u['PROXY']} /* PBXContainerItemProxy */ = {{
			isa = PBXContainerItemProxy;
			containerPortal = {u['PROJECT']} /* Project object */;
			proxyType = 1;
			remoteGlobalIDString = {u['MTARGET']};
			remoteInfo = MdirX;
		}};
		{u['PROXYUT']} /* PBXContainerItemProxy */ = {{
			isa = PBXContainerItemProxy;
			containerPortal = {u['PROJECT']} /* Project object */;
			proxyType = 1;
			remoteGlobalIDString = {u['MTARGET']};
			remoteInfo = MdirX;
		}};
{endsec("PBXContainerItemProxy")}

{sec("XCBuildConfiguration")}
		{u['DBG_APP']} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				CODE_SIGN_ENTITLEMENTS = MdirX/MdirX.entitlements;
				CODE_SIGN_STYLE = Automatic;
				COMBINE_HIDPI_IMAGES = YES;
				CURRENT_PROJECT_VERSION = 1;
				DEAD_CODE_STRIPPING = YES;
				DEVELOPMENT_TEAM = "";
				ENABLE_HARDENED_RUNTIME = YES;
				ENABLE_PREVIEWS = NO;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_CFBundleDisplayName = MdirX;
				INFOPLIST_KEY_LSApplicationCategoryType = "public.app-category.utilities";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/../Frameworks",
				);
				MACOSX_DEPLOYMENT_TARGET = 15.0;
				MARKETING_VERSION = 0.1.0;
				PRODUCT_BUNDLE_IDENTIFIER = app.mdirx.mac;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_STRICT_CONCURRENCY = complete;
				SWIFT_VERSION = 6.0;
			}};
			name = Debug;
		}};
		{u['REL_APP']} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				CODE_SIGN_ENTITLEMENTS = MdirX/MdirX.entitlements;
				CODE_SIGN_STYLE = Automatic;
				COMBINE_HIDPI_IMAGES = YES;
				CURRENT_PROJECT_VERSION = 1;
				DEAD_CODE_STRIPPING = YES;
				DEVELOPMENT_TEAM = "";
				ENABLE_HARDENED_RUNTIME = YES;
				ENABLE_PREVIEWS = NO;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_CFBundleDisplayName = MdirX;
				INFOPLIST_KEY_LSApplicationCategoryType = "public.app-category.utilities";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/../Frameworks",
				);
				ARCHS = (
					arm64,
					x86_64,
				);
				MACOSX_DEPLOYMENT_TARGET = 15.0;
				MARKETING_VERSION = 0.1.0;
				PRODUCT_BUNDLE_IDENTIFIER = app.mdirx.mac;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_STRICT_CONCURRENCY = complete;
				SWIFT_VERSION = 6.0;
			}};
			name = Release;
		}};
		{u['DBG_TEST']} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				BUNDLE_LOADER = "$(TEST_HOST)";
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = "";
				GENERATE_INFOPLIST_FILE = YES;
				MACOSX_DEPLOYMENT_TARGET = 15.0;
				MARKETING_VERSION = 0.1.0;
				PRODUCT_BUNDLE_IDENTIFIER = app.mdirx.mac.tests;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_STRICT_CONCURRENCY = complete;
				SWIFT_VERSION = 6.0;
				TEST_HOST = "$(BUILT_PRODUCTS_DIR)/MdirX.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/MdirX";
			}};
			name = Debug;
		}};
		{u['REL_TEST']} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				BUNDLE_LOADER = "$(TEST_HOST)";
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = "";
				GENERATE_INFOPLIST_FILE = YES;
				ARCHS = (
					arm64,
					x86_64,
				);
				MACOSX_DEPLOYMENT_TARGET = 15.0;
				MARKETING_VERSION = 0.1.0;
				PRODUCT_BUNDLE_IDENTIFIER = app.mdirx.mac.tests;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_STRICT_CONCURRENCY = complete;
				SWIFT_VERSION = 6.0;
				TEST_HOST = "$(BUILT_PRODUCTS_DIR)/MdirX.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/MdirX";
			}};
			name = Release;
		}};
		{u['DBG_UIT']} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = "";
				GENERATE_INFOPLIST_FILE = YES;
				MACOSX_DEPLOYMENT_TARGET = 15.0;
				MARKETING_VERSION = 0.1.0;
				PRODUCT_BUNDLE_IDENTIFIER = app.mdirx.mac.uitests;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_STRICT_CONCURRENCY = complete;
				SWIFT_VERSION = 6.0;
				TEST_TARGET_NAME = MdirX;
			}};
			name = Debug;
		}};
		{u['REL_UIT']} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = "";
				GENERATE_INFOPLIST_FILE = YES;
				ARCHS = (
					arm64,
					x86_64,
				);
				MACOSX_DEPLOYMENT_TARGET = 15.0;
				MARKETING_VERSION = 0.1.0;
				PRODUCT_BUNDLE_IDENTIFIER = app.mdirx.mac.uitests;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_STRICT_CONCURRENCY = complete;
				SWIFT_VERSION = 6.0;
				TEST_TARGET_NAME = MdirX;
			}};
			name = Release;
		}};
		{u['DBG_PROJ']} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_LOCALIZABILITY_NONLOCALIZED = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$(inherited)",
				);
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
				MACOSX_DEPLOYMENT_TARGET = 15.0;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = macosx;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
			}};
			name = Debug;
		}};
		{u['REL_PROJ']} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_LOCALIZABILITY_NONLOCALIZED = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
				MACOSX_DEPLOYMENT_TARGET = 15.0;
				MTL_ENABLE_DEBUG_INFO = NO;
				ONLY_ACTIVE_ARCH = NO;
				SDKROOT = macosx;
				SWIFT_COMPILATION_MODE = wholemodule;
			}};
			name = Release;
		}};
{endsec("XCBuildConfiguration")}

{sec("XCConfigurationList")}
		{u['ACFG']} /* Build configuration list for PBXNativeTarget "MdirX" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{u['DBG_APP']} /* Debug */,
				{u['REL_APP']} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		{u['TCFG']} /* Build configuration list for PBXNativeTarget "MdirXTests" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{u['DBG_TEST']} /* Debug */,
				{u['REL_TEST']} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		{u['UTCFG']} /* Build configuration list for PBXNativeTarget "MdirXUITests" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{u['DBG_UIT']} /* Debug */,
				{u['REL_UIT']} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		{u['PCFG']} /* Build configuration list for PBXProject "MdirX" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{u['DBG_PROJ']} /* Debug */,
				{u['REL_PROJ']} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
{endsec("XCConfigurationList")}

	}};
	rootObject = {u['PROJECT']} /* Project object */;
}}
"""

root = Path(__file__).resolve().parents[1]
out = root / "MdirX.xcodeproj" / "project.pbxproj"
out.write_text(pbx, encoding="utf-8")
print(f"Wrote {out}")
