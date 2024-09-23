// SPDX-License-Identifier: BSD-3-Clause
// SPDX-FileCopyrightText: © 2024 Serhii Olendarenko
// SPDX-FileContributor: Serhii Olendarenko <sergey.olendarenko@gmail.com>

import qbs.File
import qbs.FileInfo
import qbs.Host
import qbs.Process
import qbs.TextFile
import qbs.Utilities

Probe {
	property path conanfilePath
	property path executable: 'conan' + FileInfo.executableSuffix()
	property stringList generators: ['QbsDeps']
	property stringList additionalArguments: []

	property bool verbose: false

	property path buildDirectory: project.buildDirectory

	// optional settings
	property int compilerCStd
	property int compilerCppStd
	property string compilerLibCxx
	property string compilerRuntime
	property string compilerRuntimeType

	// always present settings
	property string arch: defaultArch
	property string buildType: defaultBuildType
	property string compiler: defaultCompiler
	property string compilerVersion: defaultCompilerVersion
	property string os: defaultOs
	property string osVersion: defaultOsVersion

	readonly property string defaultArch: qbs.architecture
	readonly property string defaultBuildType: qbs.configurationName
	readonly property string defaultCompiler: qbs.toolchainType
	readonly property string defaultCompilerVersion: qbs.toolchainVersion
	readonly property string defaultOs: qbs.targetPlatform
	readonly property string defaultOsVersion: Host.osVersionMajor() + '.' + Host.osVersionMinor()

	property int _conanfileLastModified: conanfilePath? File.lastModified(conanfilePath) : 0

	configure: {
		function buildSetting(name, value) {
			return value? ['-s:a', name + '=' + value] : []
		}

		if (!conanfilePath)
			throw('conanfilePath must be defined.')

		var reference = FileInfo.cleanPath(conanfilePath)
		console.info('Probing ' + reference)
		if (conanfilePath && !File.exists(reference))
			throw("The conanfile '" + reference + "' does not exist.")

		var args = [
			'install', reference,
			'--output-folder', buildDirectory,
		]

		const archMapping = {
			'arm64': 'armv8',
			'avr': 'avr',
			'mips': 'mips',
			'mips64': 'mips64',
			's390x': 's390x',
			'sh': 'sh4le',
			'sparc': 'sparc',
			'sparc64': 'sparcv9',
			'x86': 'x86',
			'x86_64': 'x86_64',
		}

		const buildTypeMapping = {
			'debug': 'Debug',
			'Debug': 'Debug',
			'release': 'Release',
			'Release': 'Release',
		}

		const compilerMapping = {
			'gcc': 'gcc',
			'clang': 'clang',
			'msvc': 'msvc',
			'qcc': 'qcc',
			'xcode': 'apple-clang',
		}

		const osMapping = {
			'aix': 'AIX',
			'android': 'Android',
			'freebsd': 'FreeBSD',
			'linux': 'Linux',
			'ios': 'iOS',
			'macos': 'Macos',
			'solaris': 'SunOS',
			'tvos': 'tvOS',
			'vxworks': 'VxWorks',
			'watchos': 'watchOS',
			'windows': 'Windows',
			'none': 'baremetal',
		}

		args.push(buildSetting('arch', archMapping[arch]))
		args.push(buildSetting('build_type', buildTypeMapping[buildType] || 'Release'))
		args.push(buildSetting('compiler', compilerMapping[compiler]))
		args.push(buildSetting('compiler.version', compilerVersion))
		args.push(buildSetting('compiler.libcxx', compilerLibCxx))
		args.push(buildSetting('compiler.cppstd', compilerCppStd))
		args.push(buildSetting('compiler.cstd', compilerCStd))
		args.push(buildSetting('compiler.runtime', compilerRuntime))
		args.push(buildSetting('compiler.runtime_type', compilerRuntimeType))
		args.push(buildSetting('os', osMapping[os]))
		args.push(buildSetting('os.version', osVersion))

		if (!generators.contains('QbsDeps'))
			generators.push('QbsDeps')

		args = args.concat(generators.flatMap(function(g) {
			return ['-g', g]
		}))

		args = args.flat().concat(additionalArguments).filter(function(arg) {
			return arg !== ''
		})

		const p = new Process()

		p.start(executable, args)

		while (!p.waitForFinished(500)) {
			const output = p.readStdOut()
			if (verbose && output) {
				console.info(output)
			}
		}
		while (!p.atEnd()) {
			const output = p.readStdOut()
			if (verbose && output) {
				console.info(output)
			}
		}
		if (p.exitCode()) {
			const errorOutput = p.readStdErr()
			p.close()
			throw errorOutput
		}
		p.close()

		found = true
	}
}
