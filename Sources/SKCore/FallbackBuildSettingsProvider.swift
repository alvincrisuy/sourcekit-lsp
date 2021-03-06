//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import LanguageServerProtocol
import Basic
import enum Utility.Platform

/// A simple build settings provider suitable as a fallback when accurate settings are unknown.
public final class FallbackBuildSettingsProvider: BuildSettingsProvider {

  lazy var sdkpath: AbsolutePath? = {
    if case .darwin? = Platform.currentPlatform {
      if let str = try? Process.checkNonZeroExit(args: "/usr/bin/xcrun", "--show-sdk-path", "--sdk", "macosx"), let path = try? AbsolutePath(validating: str.chomp()) {
        return path
      }
    }
    return nil
  }()

  public func settings(for url: URL, language: Language) -> FileBuildSettings? {
    guard let path = try? AbsolutePath(validating: url.path) else {
      return nil
    }

    switch language {
    case .swift:
      return settingsSwift(path: path)
    case .c, .cpp, .objective_c, .objective_cpp:
      return settingsClang(path: path, language: language)
    default:
      return nil
    }
  }

  func settingsSwift(path: AbsolutePath) -> FileBuildSettings {
    var args: [String] = []
    if let sdkpath = sdkpath {
      args += [
        "-sdk",
        sdkpath.asString,
      ]
    }
    args.append(path.asString)
    return FileBuildSettings(preferredToolchain: nil, compilerArguments: args)
  }

  func settingsClang(path: AbsolutePath, language: Language) -> FileBuildSettings {
    var args: [String] = []
    if let sdkpath = sdkpath {
      args += [
        "-isysroot",
        sdkpath.asString,
      ]
    }
    args.append(path.asString)
    return FileBuildSettings(preferredToolchain: nil, compilerArguments: args)
  }
}
